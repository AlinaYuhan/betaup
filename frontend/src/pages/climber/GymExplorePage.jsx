import { useEffect, useMemo, useRef, useState } from "react";
import api from "../../api/axios";
import EmptyState from "../../components/common/EmptyState";
import LoadingState from "../../components/common/LoadingState";
import SectionCard from "../../components/common/SectionCard";
import StatusPill from "../../components/common/StatusPill";
import { getApiErrorMessage } from "../../utils/api";

const ALL_CITIES_VALUE = "__ALL_CITIES__";
const DEFAULT_MAP_CENTER = [35.8617, 104.1954];
const DEFAULT_MAP_ZOOM = 4;
const GPS_VERIFICATION_RADIUS_METERS = 2000;
const AMAP_SCRIPT_ID = "betaup-amap-jsapi";

let amapLoadPromise = null;

function createMarkerContent(isSelected) {
  const background = isSelected ? "#ff7a18" : "#38bdf8";
  const border = isSelected ? "#ffffff" : "#ffb37a";
  const size = isSelected ? 22 : 18;

  return `
    <div
      style="
        width:${size}px;
        height:${size}px;
        border-radius:999px;
        background:${background};
        border:3px solid ${border};
        box-shadow:0 10px 24px rgba(8, 16, 24, 0.35);
      "
    ></div>
  `;
}

function createUserMarkerContent() {
  return `
    <div
      style="
        width:16px;
        height:16px;
        border-radius:999px;
        background:#38bdf8;
        border:3px solid #ffffff;
        box-shadow:0 10px 24px rgba(56, 189, 248, 0.35);
      "
    ></div>
  `;
}

async function loadAmap(config) {
  if (window.AMap) {
    return window.AMap;
  }

  if (!config?.jsKey || !config?.jsSecurityCode) {
    throw new Error("AMap JS key or security code is missing.");
  }

  if (amapLoadPromise) {
    return amapLoadPromise;
  }

  amapLoadPromise = new Promise((resolve, reject) => {
    window._AMapSecurityConfig = {
      securityJsCode: config.jsSecurityCode,
    };

    const existingScript = document.getElementById(AMAP_SCRIPT_ID);
    if (existingScript) {
      existingScript.addEventListener("load", () => resolve(window.AMap), { once: true });
      existingScript.addEventListener("error", () => {
        amapLoadPromise = null;
        reject(new Error("Failed to load AMap JS API."));
      }, { once: true });
      return;
    }

    const script = document.createElement("script");
    script.id = AMAP_SCRIPT_ID;
    script.async = true;
    script.src = `https://webapi.amap.com/maps?v=2.0&key=${encodeURIComponent(config.jsKey)}&plugin=AMap.ToolBar`;
    script.onload = () => {
      if (window.AMap) {
        resolve(window.AMap);
        return;
      }

      amapLoadPromise = null;
      reject(new Error("AMap JS API loaded, but AMap is unavailable."));
    };
    script.onerror = () => {
      amapLoadPromise = null;
      reject(new Error("Failed to load AMap JS API."));
    };

    document.head.appendChild(script);
  });

  return amapLoadPromise;
}

function splitGymTypes(types) {
  return (types ?? "")
    .split(",")
    .map((item) => item.trim())
    .filter(Boolean);
}

function formatBadgeKey(key) {
  return (key ?? "")
    .split(/[_-]+/)
    .filter(Boolean)
    .map((chunk) => chunk.charAt(0).toUpperCase() + chunk.slice(1).toLowerCase())
    .join(" ");
}

function formatDistance(distanceMeters) {
  if (!Number.isFinite(distanceMeters)) {
    return "";
  }

  if (distanceMeters < 1000) {
    return `${Math.round(distanceMeters)} m away`;
  }

  return `${(distanceMeters / 1000).toFixed(distanceMeters < 10000 ? 1 : 0)} km away`;
}

function haversineMeters(lat1, lng1, lat2, lng2) {
  const earthRadius = 6371000;
  const latDelta = ((lat2 - lat1) * Math.PI) / 180;
  const lngDelta = ((lng2 - lng1) * Math.PI) / 180;
  const lat1Radians = (lat1 * Math.PI) / 180;
  const lat2Radians = (lat2 * Math.PI) / 180;

  const a =
    Math.sin(latDelta / 2) * Math.sin(latDelta / 2) +
    Math.cos(lat1Radians) * Math.cos(lat2Radians) * Math.sin(lngDelta / 2) * Math.sin(lngDelta / 2);

  return earthRadius * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

function getLocationErrorMessage(error) {
  switch (error?.code) {
    case 1:
      return "Location access was denied.";
    case 2:
      return "Unable to determine your position.";
    case 3:
      return "Location request timed out.";
    default:
      return error?.message || "Unable to access browser location.";
  }
}

function readCurrentPosition() {
  return new Promise((resolve, reject) => {
    if (!navigator.geolocation) {
      reject(new Error("This browser does not support location services."));
      return;
    }

    navigator.geolocation.getCurrentPosition(
      (position) => {
        resolve({
          lat: position.coords.latitude,
          lng: position.coords.longitude,
        });
      },
      (error) => reject(new Error(getLocationErrorMessage(error))),
      {
        enableHighAccuracy: true,
        timeout: 8000,
        maximumAge: 0,
      },
    );
  });
}

function GymMap({ gyms, selectedGym, onSelectGymId, userLocation }) {
  const mapElementRef = useRef(null);
  const amapRef = useRef(null);
  const mapRef = useRef(null);
  const gymMarkersRef = useRef([]);
  const userOverlaysRef = useRef([]);
  const hasFittedBoundsRef = useRef(false);
  const [loadError, setLoadError] = useState("");

  useEffect(() => {
    if (!mapElementRef.current || mapRef.current) {
      return undefined;
    }

    let cancelled = false;

    async function initMap() {
      try {
        const response = await api.get("/maps/amap-config");
        const config = response.data.data ?? {};
        const AMap = await loadAmap(config);

        if (cancelled || !mapElementRef.current) {
          return;
        }

        const map = new AMap.Map(mapElementRef.current, {
          viewMode: "2D",
          resizeEnable: true,
          zoom: DEFAULT_MAP_ZOOM,
          center: [DEFAULT_MAP_CENTER[1], DEFAULT_MAP_CENTER[0]],
        });

        map.addControl(new AMap.ToolBar({
          position: {
            right: "16px",
            top: "16px",
          },
        }));

        amapRef.current = AMap;
        mapRef.current = map;
        setLoadError("");
      } catch (error) {
        if (!cancelled) {
          setLoadError(getApiErrorMessage(error, "Failed to load AMap."));
        }
      }
    }

    initMap();

    return () => {
      cancelled = true;
      if (mapRef.current) {
        mapRef.current.destroy();
      }
      amapRef.current = null;
      mapRef.current = null;
    };
  }, []);

  useEffect(() => {
    const AMap = amapRef.current;
    const map = mapRef.current;
    if (!map || !AMap) {
      return;
    }

    if (gymMarkersRef.current.length) {
      map.remove(gymMarkersRef.current);
      gymMarkersRef.current = [];
    }

    const markers = [];

    gyms.forEach((gym) => {
      if (!Number.isFinite(gym.lat) || !Number.isFinite(gym.lng)) {
        return;
      }

      const isSelected = gym.id === selectedGym?.id;
      const marker = new AMap.Marker({
        position: [gym.lng, gym.lat],
        title: gym.name,
        anchor: "center",
        offset: new AMap.Pixel(0, 0),
        content: createMarkerContent(isSelected),
      });

      marker.on("click", () => onSelectGymId(gym.id));
      marker.setLabel({
        direction: "top",
        offset: new AMap.Pixel(0, -6),
        content: `<div class="gym-amap-label">${gym.name}</div>`,
      });

      markers.push(marker);
    });

    if (markers.length) {
      map.add(markers);
    }
    gymMarkersRef.current = markers;

    if (!markers.length) {
      hasFittedBoundsRef.current = false;
      map.setZoomAndCenter(DEFAULT_MAP_ZOOM, [DEFAULT_MAP_CENTER[1], DEFAULT_MAP_CENTER[0]]);
      return;
    }

    if (selectedGym && Number.isFinite(selectedGym.lat) && Number.isFinite(selectedGym.lng)) {
      map.setCenter([selectedGym.lng, selectedGym.lat]);
      if (map.getZoom() < 11) {
        map.setZoom(11);
      }
      hasFittedBoundsRef.current = true;
      return;
    }

    if (!hasFittedBoundsRef.current) {
      map.setFitView(markers);
      if (map.getZoom() > 6) {
        map.setZoom(6);
      }
      hasFittedBoundsRef.current = true;
    }
  }, [gyms, onSelectGymId, selectedGym]);

  useEffect(() => {
    const AMap = amapRef.current;
    const map = mapRef.current;
    if (!map || !AMap) {
      return;
    }

    if (userOverlaysRef.current.length) {
      map.remove(userOverlaysRef.current);
      userOverlaysRef.current = [];
    }

    if (!userLocation) {
      return;
    }

    const userCircle = new AMap.Circle({
      center: [userLocation.lng, userLocation.lat],
      radius: 180,
      strokeColor: "#8ad7ff",
      strokeWeight: 1,
      fillColor: "#8ad7ff",
      fillOpacity: 0.12,
    });
    const userMarker = new AMap.Marker({
      position: [userLocation.lng, userLocation.lat],
      anchor: "center",
      offset: new AMap.Pixel(0, 0),
      content: createUserMarkerContent(),
      title: "Your location",
    });
    userMarker.setLabel({
      direction: "top",
      offset: new AMap.Pixel(0, -8),
      content: '<div class="gym-amap-label">Your location</div>',
    });

    map.add([userCircle, userMarker]);
    userOverlaysRef.current = [userCircle, userMarker];

    map.setCenter([userLocation.lng, userLocation.lat]);
    if (map.getZoom() < 12) {
      map.setZoom(12);
    }
  }, [userLocation]);

  if (loadError) {
    return (
      <div className="gym-map-shell">
        <div className="flex min-h-[520px] items-center justify-center px-6 text-center text-sm text-slate-300">
          {loadError}
        </div>
      </div>
    );
  }

  return (
    <div className="gym-map-shell">
      <div ref={mapElementRef} className="gym-map-canvas" />
    </div>
  );
}

export default function GymExplorePage() {
  const [gyms, setGyms] = useState([]);
  const [selectedGymId, setSelectedGymId] = useState(null);
  const [cityFilter, setCityFilter] = useState(ALL_CITIES_VALUE);
  const [userLocation, setUserLocation] = useState(null);
  const [notice, setNotice] = useState(null);
  const [error, setError] = useState("");
  const [isLoading, setIsLoading] = useState(true);
  const [isLocating, setIsLocating] = useState(false);
  const [isCheckingIn, setIsCheckingIn] = useState(false);

  useEffect(() => {
    async function loadGyms() {
      setIsLoading(true);
      setError("");

      try {
        const response = await api.get("/gyms");
        const nextGyms = Array.isArray(response.data.data) ? response.data.data : [];
        setGyms(nextGyms);
        setSelectedGymId(nextGyms[0]?.id ?? null);
      } catch (requestError) {
        setError(getApiErrorMessage(requestError, "Failed to load gyms."));
      } finally {
        setIsLoading(false);
      }
    }

    loadGyms();
  }, []);

  const cityOptions = useMemo(
    () => [...new Set(gyms.map((gym) => gym.city).filter(Boolean))].sort((left, right) => left.localeCompare(right, "zh-CN")),
    [gyms],
  );

  const filteredGyms = useMemo(
    () => (cityFilter === ALL_CITIES_VALUE ? gyms : gyms.filter((gym) => gym.city === cityFilter)),
    [cityFilter, gyms],
  );

  useEffect(() => {
    if (!filteredGyms.length) {
      setSelectedGymId(null);
      return;
    }

    if (!filteredGyms.some((gym) => gym.id === selectedGymId)) {
      setSelectedGymId(filteredGyms[0].id);
    }
  }, [filteredGyms, selectedGymId]);

  const selectedGym = useMemo(
    () => filteredGyms.find((gym) => gym.id === selectedGymId) ?? null,
    [filteredGyms, selectedGymId],
  );

  const selectedDistance = useMemo(() => {
    if (!selectedGym || !userLocation) {
      return null;
    }

    return haversineMeters(userLocation.lat, userLocation.lng, selectedGym.lat, selectedGym.lng);
  }, [selectedGym, userLocation]);

  const nearbyGymCount = useMemo(() => {
    if (!userLocation) {
      return 0;
    }

    return filteredGyms.filter(
      (gym) => haversineMeters(userLocation.lat, userLocation.lng, gym.lat, gym.lng) <= GPS_VERIFICATION_RADIUS_METERS,
    ).length;
  }, [filteredGyms, userLocation]);

  const handleLocateUser = async () => {
    setNotice(null);
    setIsLocating(true);

    try {
      const location = await readCurrentPosition();
      const gymsWithinRange = filteredGyms.filter(
        (gym) => haversineMeters(location.lat, location.lng, gym.lat, gym.lng) <= GPS_VERIFICATION_RADIUS_METERS,
      ).length;
      setUserLocation(location);
      setNotice({
        tone: gymsWithinRange > 0 ? "success" : "info",
        message: "Location updated. The map has centered on your current position.",
      });
    } catch (locationError) {
      setNotice({
        tone: "error",
        message: locationError.message,
      });
    } finally {
      setIsLocating(false);
    }
  };

  const handleCheckIn = async (mode) => {
    if (!selectedGym) {
      return;
    }

    setNotice(null);
    setIsCheckingIn(true);

    try {
      let gpsLocation = null;

      if (mode === "gps") {
        gpsLocation = await readCurrentPosition();
        setUserLocation(gpsLocation);
      }

      const response = await api.post("/checkins", {
        gymId: selectedGym.id,
        ...(gpsLocation
          ? {
              userLat: gpsLocation.lat,
              userLng: gpsLocation.lng,
            }
          : {}),
      });

      const result = response.data.data ?? {};
      setNotice({
        tone: result.checkInId ? "success" : "warm",
        message:
          response.data.message ||
          (result.gpsVerified ? "GPS check-in successful." : "Manual check-in recorded."),
        badges: Array.isArray(result.newBadgeKeys) ? result.newBadgeKeys : [],
      });
    } catch (requestError) {
      setNotice({
        tone: "error",
        message: getApiErrorMessage(requestError, "Check-in failed."),
      });
    } finally {
      setIsCheckingIn(false);
    }
  };

  return (
    <div className="grid gap-4">
      <section className="glass-panel overflow-hidden p-6 sm:p-8">
        <div className="flex flex-col gap-6 lg:flex-row lg:items-end lg:justify-between">
          <div>
            <span className="eyebrow">Explore</span>
            <h2 className="max-w-3xl text-3xl font-semibold text-white sm:text-4xl">
              Open the gym map, select a venue, and check in from the same screen.
            </h2>
            <p className="mt-4 max-w-2xl text-sm leading-7 text-slate-300">
              The web app now uses the live gym catalog and the same check-in API as the mobile flow. Pick a city, click a marker,
              and use GPS or manual check-in without leaving the page.
            </p>
          </div>

          <div className="flex flex-wrap items-center gap-3">
            <select className="field-input w-full sm:w-48" value={cityFilter} onChange={(event) => setCityFilter(event.target.value)}>
              <option value={ALL_CITIES_VALUE}>All cities</option>
              {cityOptions.map((city) => (
                <option key={city} value={city}>
                  {city}
                </option>
              ))}
            </select>
            <button
              type="button"
              className="secondary-button disabled:cursor-not-allowed disabled:opacity-60"
              disabled={isLocating}
              onClick={handleLocateUser}
            >
              {isLocating ? "Locating..." : "Locate Me"}
            </button>
            <StatusPill label={`${filteredGyms.length} gyms`} />
            {userLocation ? (
              <StatusPill
                label={nearbyGymCount > 0 ? `${nearbyGymCount} within ${GPS_VERIFICATION_RADIUS_METERS}m` : "Location ready"}
                tone={nearbyGymCount > 0 ? "success" : "warm"}
              />
            ) : null}
          </div>
        </div>

        {notice ? (
          <div
            className={[
              "mt-6 rounded-2xl border px-4 py-4 text-sm",
              notice.tone === "error"
                ? "border-rose-400/20 bg-rose-400/10 text-rose-200"
                : notice.tone === "warm"
                  ? "border-amber-400/20 bg-amber-400/10 text-amber-100"
                  : "border-emerald-400/20 bg-emerald-400/10 text-emerald-100",
            ].join(" ")}
          >
            <p>{notice.message}</p>
            {notice.badges?.length ? (
              <div className="mt-3 flex flex-wrap gap-2">
                {notice.badges.map((badgeKey) => (
                  <span
                    key={badgeKey}
                    className="rounded-full border border-white/10 bg-white/10 px-3 py-1 text-xs font-semibold uppercase tracking-[0.18em]"
                  >
                    {formatBadgeKey(badgeKey)}
                  </span>
                ))}
              </div>
            ) : null}
          </div>
        ) : null}
      </section>

      {isLoading ? <LoadingState label="Loading gyms" /> : null}
      {!isLoading && error ? <EmptyState title="Gym map unavailable" description={error} /> : null}

      {!isLoading && !error ? (
        filteredGyms.length ? (
          <div className="grid gap-4 xl:grid-cols-[minmax(0,1.65fr)_minmax(340px,0.95fr)]">
            <section className="glass-panel overflow-hidden p-4">
              <div className="mb-4 flex flex-wrap items-center justify-between gap-4 px-2">
                <div>
                  <p className="text-lg font-semibold text-white">Gym map</p>
                  <p className="mt-1 text-xs uppercase tracking-[0.2em] text-slate-500">
                    Click any marker to sync the venue details and check-in panel
                  </p>
                </div>
                {selectedGym ? <StatusPill label={selectedGym.city || "Selected gym"} tone="warm" /> : null}
              </div>
              <GymMap gyms={filteredGyms} selectedGym={selectedGym} onSelectGymId={setSelectedGymId} userLocation={userLocation} />
            </section>

            <div className="grid gap-4">
              <SectionCard
                title={selectedGym?.name || "Gym detail"}
                kicker="Selected Venue"
                action={
                  selectedDistance != null ? (
                    <StatusPill label={formatDistance(selectedDistance)} tone={selectedDistance <= GPS_VERIFICATION_RADIUS_METERS ? "success" : "warm"} />
                  ) : null
                }
              >
                {selectedGym ? (
                  <div className="space-y-5">
                    <div>
                      <p className="text-sm uppercase tracking-[0.2em] text-slate-500">{selectedGym.city}</p>
                      <p className="mt-2 text-sm leading-7 text-slate-300">{selectedGym.address}</p>
                    </div>

                    {splitGymTypes(selectedGym.types).length ? (
                      <div className="flex flex-wrap gap-2">
                        {splitGymTypes(selectedGym.types).map((type) => (
                          <span
                            key={type}
                            className="rounded-full border border-ice/15 bg-ice/10 px-3 py-1 text-xs font-semibold uppercase tracking-[0.16em] text-ice"
                          >
                            {type}
                          </span>
                        ))}
                      </div>
                    ) : null}

                    <div className="grid gap-3">
                      <div className="rounded-2xl border border-white/10 bg-white/5 p-4">
                        <p className="text-xs uppercase tracking-[0.18em] text-slate-500">Open Hours</p>
                        <p className="mt-2 text-sm text-slate-200">{selectedGym.openHours || "Not provided"}</p>
                      </div>

                      <div className="rounded-2xl border border-white/10 bg-white/5 p-4">
                        <p className="text-xs uppercase tracking-[0.18em] text-slate-500">Phone</p>
                        <p className="mt-2 text-sm text-slate-200">{selectedGym.phone || "Not provided"}</p>
                      </div>

                      {selectedGym.bookingUrl ? (
                        <a className="secondary-button w-full" href={selectedGym.bookingUrl} rel="noreferrer" target="_blank">
                          Open Booking Link
                        </a>
                      ) : null}
                    </div>

                    <div className="rounded-2xl border border-white/10 bg-slate-950/50 p-4">
                      <p className="text-sm leading-7 text-slate-300">
                        GPS check-in validates whether you are within {GPS_VERIFICATION_RADIUS_METERS} meters of this gym. Manual
                        check-in still records the visit, but without GPS verification.
                      </p>
                    </div>

                    <div className="grid gap-3 sm:grid-cols-2">
                      <button
                        type="button"
                        className="primary-button w-full disabled:cursor-not-allowed disabled:opacity-60"
                        disabled={isCheckingIn}
                        onClick={() => handleCheckIn("gps")}
                      >
                        {isCheckingIn ? "Checking..." : "GPS Check-In"}
                      </button>
                      <button
                        type="button"
                        className="secondary-button w-full disabled:cursor-not-allowed disabled:opacity-60"
                        disabled={isCheckingIn}
                        onClick={() => handleCheckIn("manual")}
                      >
                        Manual Check-In
                      </button>
                    </div>
                  </div>
                ) : (
                  <EmptyState title="No gym selected" description="Choose a marker or a gym from the list to inspect details." />
                )}
              </SectionCard>

              <SectionCard title="Gym roster" kicker="Venue List" action={<StatusPill label={`${filteredGyms.length} visible`} />}>
                <div className="grid max-h-[520px] gap-3 overflow-auto pr-1">
                  {filteredGyms.map((gym) => {
                    const isSelected = gym.id === selectedGym?.id;
                    const distance = userLocation ? haversineMeters(userLocation.lat, userLocation.lng, gym.lat, gym.lng) : null;

                    return (
                      <button
                        key={gym.id}
                        type="button"
                        className={[
                          "rounded-2xl border p-4 text-left transition",
                          isSelected
                            ? "border-ember/50 bg-ember/10 text-white"
                            : "border-white/10 bg-white/5 text-slate-200 hover:border-ice/25 hover:bg-white/10",
                        ].join(" ")}
                        onClick={() => setSelectedGymId(gym.id)}
                      >
                        <div className="flex flex-wrap items-start justify-between gap-3">
                          <div>
                            <p className="text-base font-semibold">{gym.name}</p>
                            <p className="mt-1 text-xs uppercase tracking-[0.18em] text-slate-500">{gym.city}</p>
                          </div>
                          {distance != null ? (
                            <span className="rounded-full border border-white/10 bg-black/20 px-3 py-1 text-xs font-semibold uppercase tracking-[0.16em]">
                              {formatDistance(distance)}
                            </span>
                          ) : null}
                        </div>

                        <p className="mt-3 text-sm leading-7 text-slate-300">{gym.address}</p>

                        {splitGymTypes(gym.types).length ? (
                          <div className="mt-3 flex flex-wrap gap-2">
                            {splitGymTypes(gym.types).map((type) => (
                              <span key={`${gym.id}-${type}`} className="rounded-full border border-white/10 bg-black/20 px-3 py-1 text-xs text-slate-300">
                                {type}
                              </span>
                            ))}
                          </div>
                        ) : null}
                      </button>
                    );
                  })}
                </div>
              </SectionCard>
            </div>
          </div>
        ) : (
          <EmptyState title="No gyms in this view" description="Change the city filter to show gyms on the map again." />
        )
      ) : null}
    </div>
  );
}
