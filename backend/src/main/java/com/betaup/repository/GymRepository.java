package com.betaup.repository;

import com.betaup.entity.Gym;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface GymRepository extends JpaRepository<Gym, Long> {

    List<Gym> findByCity(String city);
}
