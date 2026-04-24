package com.betaup.config;

import com.betaup.entity.Gym;
import com.betaup.repository.GymRepository;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.StatementCallback;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
public class GymDataInitializer implements ApplicationRunner {

    private final GymRepository gymRepository;
    private final JdbcTemplate jdbcTemplate;

    // 每次修改岩馆列表后更新此数字，重启后端自动重新 seed，无需手动删数据库文件
    private static final int EXPECTED_COUNT = 33;

    @Override
    public void run(ApplicationArguments args) {
        if (gymRepository.count() == EXPECTED_COUNT) {
            return;
        }
        // StatementCallback guarantees all three SQL statements run on the SAME connection,
        // so the H2 session-level setting takes effect for the DELETE.
        jdbcTemplate.execute((StatementCallback<Void>) stmt -> {
            stmt.execute("SET REFERENTIAL_INTEGRITY FALSE");
            stmt.execute("DELETE FROM gyms");
            stmt.execute("SET REFERENTIAL_INTEGRITY TRUE");
            return null;
        });

        // Coordinates are WGS84 to match OpenStreetMap tile layer
        List<Gym> gyms = List.of(
            // ── 苏州（重点城市，XJTLU 所在地）────────────────────────────────
            Gym.builder().name("西交利物浦大学攀岩馆").city("苏州")
                .address("苏州市工业园区仁爱路111号西浦校园南区体育馆")
                .lat(31.2722).lng(120.7368)
                .phone("0512-88161000").openHours("09:00-21:00")
                .types("boulder,lead").bookingUrl("").coverImageUrl("").logoUrl("").build(),

            Gym.builder().name("刘常忠攀岩馆(独墅湖店)").city("苏州")
                .address("苏州市工业园区独墅湖科教创新区")
                .lat(31.2691).lng(120.7229)
                .phone("0512-62880088").openHours("13:00-21:30")
                .types("boulder").bookingUrl("https://www.meituan.com/meishi/suzhou-lcz")
                .coverImageUrl("").logoUrl("").build(),

            Gym.builder().name("刘常忠攀岩馆(奥体中心店)").city("苏州")
                .address("苏州市工业园区苏州奥林匹克体育中心旁")
                .lat(31.3075).lng(120.7430)
                .phone("0512-62880099").openHours("13:00-21:30")
                .types("boulder,lead").bookingUrl("https://www.meituan.com/meishi/suzhou-lcz2")
                .coverImageUrl("").logoUrl("").build(),

            Gym.builder().name("九星龙国际攀岩(圆融时代广场)").city("苏州")
                .address("苏州市工业园区圆融时代广场")
                .lat(31.3232).lng(120.7095)
                .phone("0512-65001234").openHours("10:00-21:30")
                .types("boulder,lead").bookingUrl("https://www.meituan.com/meishi/suzhou-jxl")
                .coverImageUrl("").logoUrl("").build(),

            Gym.builder().name("Follow Away Climbing跟攀攀岩").city("苏州")
                .address("苏州市工业园区新区域（苏州攀岩榜NO.2）")
                .lat(31.3108).lng(120.7420)
                .phone("0512-66880088").openHours("13:00-22:00")
                .types("boulder").bookingUrl("https://www.meituan.com/meishi/suzhou-followaway")
                .coverImageUrl("").logoUrl("").build(),

            Gym.builder().name("星空攀岩(尹山湖歌林公园店)").city("苏州")
                .address("苏州市吴中区尹山湖歌林公园内")
                .lat(31.2411).lng(120.6811)
                .phone("0512-66123456").openHours("13:00-21:00")
                .types("boulder,lead").bookingUrl("https://www.meituan.com/meishi/suzhou-starry1")
                .coverImageUrl("").logoUrl("").build(),

            Gym.builder().name("星空攀岩(苏州湾歌林公园店)").city("苏州")
                .address("苏州市吴江区苏州湾歌林公园")
                .lat(31.1580).lng(120.6340)
                .phone("0512-66123488").openHours("10:00-22:00")
                .types("boulder,lead").bookingUrl("https://www.meituan.com/meishi/suzhou-starry2")
                .coverImageUrl("").logoUrl("").build(),

            Gym.builder().name("攀月攀岩(相城天街店)").city("苏州")
                .address("苏州市相城区相城天街购物中心")
                .lat(31.3692).lng(120.6456)
                .phone("0512-67881234").openHours("10:00-22:00")
                .types("boulder").bookingUrl("https://www.meituan.com/meishi/suzhou-panyue1")
                .coverImageUrl("").logoUrl("").build(),

            Gym.builder().name("攀月攀岩(绿宝广场店)").city("苏州")
                .address("苏州市工业园区绿宝广场")
                .lat(31.3340).lng(120.7080)
                .phone("0512-67881266").openHours("10:00-21:30")
                .types("boulder").bookingUrl("https://www.meituan.com/meishi/suzhou-panyue2")
                .coverImageUrl("").logoUrl("").build(),

            Gym.builder().name("攀猩攀岩馆(星澜荟店)").city("苏州")
                .address("苏州市工业园区星澜荟购物中心")
                .lat(31.3178).lng(120.7415)
                .phone("0512-62001234").openHours("10:00-22:00")
                .types("boulder").bookingUrl("https://www.meituan.com/meishi/suzhou-panxing")
                .coverImageUrl("").logoUrl("").build(),

            Gym.builder().name("苏州奥林匹克体育中心攀岩馆").city("苏州")
                .address("苏州市工业园区苏州奥林匹克体育中心")
                .lat(31.3069).lng(120.7444)
                .phone("0512-62218888").openHours("10:00-22:00")
                .types("boulder,lead,speed").bookingUrl("https://www.meituan.com/meishi/suzhou-olympic")
                .coverImageUrl("").logoUrl("").build(),

            Gym.builder().name("考拉攀岩(狮山店)").city("苏州")
                .address("苏州市高新区狮山路")
                .lat(31.2773).lng(120.5393)
                .phone("0512-68991234").openHours("13:00-22:00")
                .types("boulder").bookingUrl("https://www.meituan.com/meishi/suzhou-koala")
                .coverImageUrl("").logoUrl("").build(),

            // ── 北京 ──────────────────────────────────────────────────────────
            Gym.builder().name("野石攀岩·望京SOHO").city("北京")
                .address("北京市朝阳区望京SOHO T1塔1层")
                .lat(39.9946).lng(116.4883)
                .phone("010-84717799").openHours("10:00-22:00")
                .types("boulder,lead").bookingUrl("https://www.dianping.com/shop/bj-yeshi")
                .coverImageUrl("").logoUrl("").build(),

            Gym.builder().name("石浪攀岩·五道口").city("北京")
                .address("北京市海淀区五道口华清嘉园")
                .lat(40.0048).lng(116.3376)
                .phone("010-82373399").openHours("09:00-22:00")
                .types("boulder").bookingUrl("").coverImageUrl("").logoUrl("").build(),

            Gym.builder().name("极石攀岩·朝阳大悦城").city("北京")
                .address("北京市朝阳区朝阳北路101号大悦城")
                .lat(39.9233).lng(116.5127)
                .phone("010-57608866").openHours("10:00-22:00")
                .types("boulder,lead").bookingUrl("https://www.dianping.com/shop/bj-jishi")
                .coverImageUrl("").logoUrl("").build(),

            Gym.builder().name("ClimbX攀岩馆·中关村").city("北京")
                .address("北京市海淀区中关村大街27号")
                .lat(39.9667).lng(116.3146)
                .phone("010-62600088").openHours("10:00-21:30")
                .types("boulder").bookingUrl("").coverImageUrl("").logoUrl("").build(),

            // ── 上海 ──────────────────────────────────────────────────────────
            Gym.builder().name("攀岩上海·徐汇滨江").city("上海")
                .address("上海市徐汇区龙腾大道2879号")
                .lat(31.1723).lng(121.4568)
                .phone("021-54361234").openHours("10:00-22:00")
                .types("boulder,lead,speed").bookingUrl("")
                .coverImageUrl("").logoUrl("").build(),

            Gym.builder().name("熊猫攀岩·静安大融城").city("上海")
                .address("上海市静安区恒丰路150号大融城B1")
                .lat(31.2814).lng(121.4228)
                .phone("021-32185599").openHours("10:00-22:00")
                .types("boulder").bookingUrl("").coverImageUrl("").logoUrl("").build(),

            Gym.builder().name("V12攀岩·浦东张江").city("上海")
                .address("上海市浦东新区张江高科技园区碧波路690号")
                .lat(31.2041).lng(121.5988)
                .phone("021-50800012").openHours("09:00-21:30")
                .types("boulder,lead").bookingUrl("")
                .coverImageUrl("").logoUrl("").build(),

            Gym.builder().name("爬爬岩攀岩·杨浦").city("上海")
                .address("上海市杨浦区控江路1557弄")
                .lat(31.2743).lng(121.5207)
                .phone("021-65512299").openHours("10:00-22:00")
                .types("boulder").bookingUrl("").coverImageUrl("").logoUrl("").build(),

            // ── 广州 ──────────────────────────────────────────────────────────
            Gym.builder().name("极石攀岩·天河体育中心").city("广州")
                .address("广州市天河区体育西路1号天河体育中心")
                .lat(23.1375).lng(113.3228)
                .phone("020-38756688").openHours("10:00-22:00")
                .types("boulder,lead").bookingUrl("").coverImageUrl("").logoUrl("").build(),

            Gym.builder().name("岩壁攀岩·番禺万达").city("广州")
                .address("广州市番禺区市桥街万达广场")
                .lat(22.9348).lng(113.3659)
                .phone("020-34823399").openHours("10:00-22:00")
                .types("boulder").bookingUrl("").coverImageUrl("").logoUrl("").build(),

            // ── 深圳 ──────────────────────────────────────────────────────────
            Gym.builder().name("宝岩攀岩·南山科技园").city("深圳")
                .address("深圳市南山区科技园南区高新南一道")
                .lat(22.5338).lng(113.9477)
                .phone("0755-86013388").openHours("10:00-22:00")
                .types("boulder,lead").bookingUrl("")
                .coverImageUrl("").logoUrl("").build(),

            Gym.builder().name("上岩攀岩·龙华壹方城").city("深圳")
                .address("深圳市龙华区民治大道壹方城购物中心")
                .lat(22.6356).lng(114.0289)
                .phone("0755-28018866").openHours("10:00-22:00")
                .types("boulder").bookingUrl("").coverImageUrl("").logoUrl("").build(),

            // ── 成都 ──────────────────────────────────────────────────────────
            Gym.builder().name("巨石攀岩·高新万象城").city("成都")
                .address("成都市高新区天府大道北段1700号万象城")
                .lat(30.5728).lng(104.0632)
                .phone("028-85561234").openHours("10:00-22:00")
                .types("boulder,lead").bookingUrl("").coverImageUrl("").logoUrl("").build(),

            Gym.builder().name("耀岩攀岩·锦江区").city("成都")
                .address("成都市锦江区水晶城购物中心")
                .lat(30.6502).lng(104.1073)
                .phone("028-87661122").openHours("10:00-22:00")
                .types("boulder").bookingUrl("").coverImageUrl("").logoUrl("").build(),

            // ── 杭州 ──────────────────────────────────────────────────────────
            Gym.builder().name("岩趣攀岩·西湖文三路").city("杭州")
                .address("杭州市西湖区文三路398号")
                .lat(30.2790).lng(120.1227)
                .phone("0571-87662288").openHours("10:00-21:30")
                .types("boulder,lead").bookingUrl("").coverImageUrl("").logoUrl("").build(),

            Gym.builder().name("极限攀岩·滨江宝龙").city("杭州")
                .address("杭州市滨江区滨盛路宝龙城市广场")
                .lat(30.2071).lng(120.2124)
                .phone("0571-86699988").openHours("10:00-22:00")
                .types("boulder").bookingUrl("").coverImageUrl("").logoUrl("").build(),

            // ── 南京 ──────────────────────────────────────────────────────────
            Gym.builder().name("绿岩攀岩·鼓楼紫峰").city("南京")
                .address("南京市鼓楼区中山北路8号紫峰大厦附近")
                .lat(32.0625).lng(118.7780)
                .phone("025-83337799").openHours("10:00-21:00")
                .types("boulder").bookingUrl("").coverImageUrl("").logoUrl("").build(),

            // ── 武汉 ──────────────────────────────────────────────────────────
            Gym.builder().name("磐石攀岩·武昌楚河汉街").city("武汉")
                .address("武汉市武昌区楚河汉街水岸国际")
                .lat(30.5486).lng(114.3304)
                .phone("027-87788899").openHours("10:00-22:00")
                .types("boulder,lead").bookingUrl("").coverImageUrl("").logoUrl("").build(),

            // ── 重庆 ──────────────────────────────────────────────────────────
            Gym.builder().name("崖壁攀岩·渝中观音桥").city("重庆")
                .address("重庆市江北区观音桥步行街")
                .lat(29.5726).lng(106.5655)
                .phone("023-67889900").openHours("10:00-22:00")
                .types("boulder,lead").bookingUrl("").coverImageUrl("").logoUrl("").build(),

            // ── 西安 ──────────────────────────────────────────────────────────
            Gym.builder().name("秦岭攀岩·曲江大悦城").city("西安")
                .address("西安市雁塔区曲江新区大雁塔北广场")
                .lat(34.2134).lng(108.9598)
                .phone("029-85168866").openHours("10:00-22:00")
                .types("boulder").bookingUrl("").coverImageUrl("").logoUrl("").build(),

            // ── 天津 ──────────────────────────────────────────────────────────
            Gym.builder().name("津攀攀岩·河西友谊路").city("天津")
                .address("天津市河西区友谊路与平江道交口")
                .lat(39.0962).lng(117.2108)
                .phone("022-28368899").openHours("10:00-21:30")
                .types("boulder,lead").bookingUrl("").coverImageUrl("").logoUrl("").build()
        );

        gymRepository.saveAll(gyms);
    }
}
