import React from "react";

export default function LoadingState({ label = "Loading..." }) {
  return (
    <div className="flex min-h-[220px] items-center justify-center rounded-3xl border border-white/10 bg-white/5 p-8">
      <div className="text-center">
        <div className="mx-auto h-10 w-10 animate-spin rounded-full border-2 border-white/15 border-t-ember" />
        <p className="mt-4 text-sm uppercase tracking-[0.25em] text-slate-400">{label}</p>
      </div>
    </div>
  );
}
