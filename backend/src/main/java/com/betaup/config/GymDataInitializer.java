package com.betaup.config;

import com.betaup.entity.Gym;
import com.betaup.repository.GymRepository;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
public class GymDataInitializer implements ApplicationRunner {

    private final GymRepository gymRepository;

    @Override
    public void run(ApplicationArguments args) {
        if (gymRepository.count() > 0) {
            return; // Already seeded
        }

        List<Gym> gyms = List.of(
            // Beijing
            Gym.builder().name("攀岩北京·朝阳馆").city("北京").address("北京市朝阳区望京SOHO T1").lat(39.9956).lng(116.4915).phone("010-12345678").openHours("10:00-22:00").types("boulder,lead").bookingUrl("https://example.com/booking/bj1").coverImageUrl("").logoUrl("").build(),
            Gym.builder().name("石浪攀岩·五道口").city("北京").address("北京市海淀区成府路五道口").lat(40.0045).lng(116.3380).phone("010-23456789").openHours("09:00-21:00").types("boulder").bookingUrl("https://example.com/booking/bj2").coverImageUrl("").logoUrl("").build(),
            // Shanghai
            Gym.builder().name("V12攀岩馆·徐汇").city("上海").address("上海市徐汇区漕宝路V12攀岩").lat(31.1800).lng(121.4200).phone("021-12345678").openHours("10:00-22:00").types("boulder,lead,speed").bookingUrl("https://example.com/booking/sh1").coverImageUrl("").logoUrl("").build(),
            Gym.builder().name("熊猫攀岩·浦东").city("上海").address("上海市浦东新区张杨路熊猫攀岩").lat(31.2210).lng(121.5220).phone("021-23456789").openHours("10:00-21:30").types("boulder").bookingUrl("https://example.com/booking/sh2").coverImageUrl("").logoUrl("").build(),
            // Guangzhou
            Gym.builder().name("极石攀岩·天河").city("广州").address("广州市天河区体育西路极石攀岩").lat(23.1330).lng(113.3230).phone("020-12345678").openHours("10:00-22:00").types("boulder,lead").bookingUrl("https://example.com/booking/gz1").coverImageUrl("").logoUrl("").build(),
            // Shenzhen
            Gym.builder().name("宝岩攀岩·南山").city("深圳").address("深圳市南山区科技园宝岩攀岩").lat(22.5370).lng(113.9540).phone("0755-12345678").openHours("10:00-22:00").types("boulder").bookingUrl("https://example.com/booking/sz1").coverImageUrl("").logoUrl("").build(),
            Gym.builder().name("上岩攀岩·福田").city("深圳").address("深圳市福田区华强北上岩攀岩").lat(22.5460).lng(114.0870).phone("0755-23456789").openHours("10:00-21:00").types("boulder,lead").bookingUrl("https://example.com/booking/sz2").coverImageUrl("").logoUrl("").build(),
            // Chengdu
            Gym.builder().name("巨石攀岩·高新区").city("成都").address("成都市高新区天府大道巨石攀岩").lat(30.5750).lng(104.0650).phone("028-12345678").openHours("10:00-22:00").types("boulder").bookingUrl("https://example.com/booking/cd1").coverImageUrl("").logoUrl("").build(),
            // Hangzhou
            Gym.builder().name("岩壁攀岩·西湖").city("杭州").address("杭州市西湖区文三路岩壁攀岩").lat(30.2580).lng(120.1240).phone("0571-12345678").openHours("10:00-21:00").types("boulder,lead").bookingUrl("https://example.com/booking/hz1").coverImageUrl("").logoUrl("").build(),
            // Nanjing
            Gym.builder().name("绿岩攀岩·鼓楼").city("南京").address("南京市鼓楼区中山北路绿岩攀岩").lat(32.0680).lng(118.7830).phone("025-12345678").openHours("10:00-21:00").types("boulder").bookingUrl("https://example.com/booking/nj1").coverImageUrl("").logoUrl("").build(),
            // Wuhan
            Gym.builder().name("磐石攀岩·武昌").city("武汉").address("武汉市武昌区中南路磐石攀岩").lat(30.5460).lng(114.3270).phone("027-12345678").openHours("10:00-21:00").types("boulder,lead").bookingUrl("https://example.com/booking/wh1").coverImageUrl("").logoUrl("").build(),
            // Suzhou
            Gym.builder().name("岩石攀岩·工业园区").city("苏州").address("苏州市工业园区金鸡湖岩石攀岩").lat(31.2980).lng(120.7120).phone("0512-12345678").openHours("10:00-21:00").types("boulder").bookingUrl("https://example.com/booking/sz3").coverImageUrl("").logoUrl("").build(),
            // Chongqing
            Gym.builder().name("崖壁攀岩·渝中").city("重庆").address("重庆市渝中区解放碑崖壁攀岩").lat(29.5560).lng(106.5760).phone("023-12345678").openHours("10:00-22:00").types("boulder,lead").bookingUrl("https://example.com/booking/cq1").coverImageUrl("").logoUrl("").build(),
            // Xi'an
            Gym.builder().name("秦岭攀岩·雁塔").city("西安").address("西安市雁塔区小寨路秦岭攀岩").lat(34.2150).lng(108.9440).phone("029-12345678").openHours("10:00-21:00").types("boulder").bookingUrl("https://example.com/booking/xa1").coverImageUrl("").logoUrl("").build(),
            // Tianjin
            Gym.builder().name("津攀攀岩·河西").city("天津").address("天津市河西区友谊路津攀攀岩").lat(39.0960).lng(117.2110).phone("022-12345678").openHours("10:00-21:00").types("boulder,lead").bookingUrl("https://example.com/booking/tj1").coverImageUrl("").logoUrl("").build()
        );

        gymRepository.saveAll(gyms);
    }
}
