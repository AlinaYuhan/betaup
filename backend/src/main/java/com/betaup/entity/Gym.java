package com.betaup.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "gyms")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Gym {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 120)
    private String name;

    @Column(nullable = false, length = 60)
    private String city;

    @Column(nullable = false, length = 255)
    private String address;

    @Column(nullable = false)
    private double lat;

    @Column(nullable = false)
    private double lng;

    @Column(length = 30)
    private String phone;

    @Column(length = 100)
    private String openHours;

    // Comma-separated: e.g. "lead,boulder,speed"
    @Column(length = 100)
    private String types;

    @Column(length = 255)
    private String bookingUrl;

    @Column(length = 255)
    private String coverImageUrl;

    @Column(length = 255)
    private String logoUrl;
}
