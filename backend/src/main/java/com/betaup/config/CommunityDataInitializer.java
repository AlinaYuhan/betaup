package com.betaup.config;

import com.betaup.entity.*;
import com.betaup.repository.*;
import jakarta.persistence.EntityManager;
import java.time.LocalDateTime;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.core.annotation.Order;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

/**
 * Seeds demo community posts, users and comments for development / demo purposes.
 * Guarded by the presence of the sentinel account sarah@betaup.com.
 */
@Slf4j
@Component
@Order(10)
@RequiredArgsConstructor
public class CommunityDataInitializer implements ApplicationRunner {

    private final UserRepository    userRepository;
    private final PostRepository    postRepository;
    private final CommentRepository commentRepository;
    private final PasswordEncoder   passwordEncoder;
    private final EntityManager     em;

    @Override
    @Transactional
    public void run(ApplicationArguments args) {
        if (userRepository.existsByEmailIgnoreCase("sarah@betaup.com")) {
            log.debug("[Community] Demo data already seeded, skipping.");
            return;
        }

        String pw = passwordEncoder.encode("12345678");

        // ── Demo users (simple names, betaup.com emails) ─────────────────────
        User sarah = save("Sarah",  "sarah@betaup.com",  pw, "苏州", "Sport + bouldering. Trying to break into V6.");
        User mike  = save("Mike",   "mike@betaup.com",   pw, "上海", "Outdoor climber, 5.12 sport. Love weekend crags.");
        User lisa  = save("Lisa",   "lisa@betaup.com",   pw, "苏州", "新手一枚，V3~V4 水平，欢迎大家带我！");
        User dada  = save("大毛",   "dada@betaup.com",   pw, "苏州", "Campus Wall 常客，V9 努力中。");
        User tom   = save("Tom",    "tom@betaup.com",    pw, "南京", "Routesetter & coach in training.");
        User jay   = save("Jay",    "jay@betaup.com",    pw, "苏州", "V7 boulderer, love slopers and compression.");

        // ── Posts ─────────────────────────────────────────────────────────────
        LocalDateTime now = LocalDateTime.now();

        Post p1  = post(jay,
            "Just flashed my first V6 at Campus Wall! The beta is all about the left-hand sidepull on move 3 — don't skip it. Took me 3 sessions to figure it out but today everything clicked 🎉",
            PostType.GENERAL, false, null, 14, 3, now.minusHours(2));

        Post p2  = post(sarah,
            "Looking for a climbing partner this Saturday afternoon at Campus Wall. I'm working V4–V5 boulders and would love someone to share beta with. DM me! 🙌",
            PostType.FIND_PARTNER, false, null, 6, 2, now.minusHours(5));

        Post p3  = post(mike,
            "Beta drop for the crimpy V7 in the overhang sector (yellow tape, set last week): start matched on the big jug, move right to the two-finger pocket, then deadpoint to the sloper. Do NOT use the blue hold — it's off. Took me 10 tries.",
            PostType.GENERAL, true, "Campus Wall Yellow V7", 22, 5, now.minusDays(1));

        Post p4  = post(tom,
            "Finished setting a new V5 slab in the training room today. Footwork-heavy — you'll need to trust your smears. Come try it and let me know if it reads well!",
            PostType.GENERAL, false, null, 9, 1, now.minusDays(1).minusHours(3));

        Post p5  = post(jay,
            "Anyone else notice the new moonboard angles feel way steeper than before? My V6 problems are feeling like V7 now lol. Maybe a good thing 🤷",
            PostType.GENERAL, false, null, 11, 4, now.minusDays(2));

        Post p6  = post(dada,
            "今天终于把 V8 那条黑色的送了！！！连续尝试了两个月，最后关键在第四步的一个小旗步，大家做那条的时候试试看。Campus Wall 二楼右侧。",
            PostType.GENERAL, false, null, 31, 7, now.minusDays(1).minusHours(1));

        Post p7  = post(lisa,
            "有没有人这周六下午在 Campus Wall？我刚开始爬岩不久，V3 水平，想找个人一起练习顺便请教一下技巧 😊 新手求带！",
            PostType.FIND_PARTNER, false, null, 8, 3, now.minusHours(8));

        Post p8  = post(sarah,
            "分享一条 V5 的 Beta，月石攀岩蓝色贴条那条：\n1. 起步双手并排抠 crimp\n2. 第三步不要用脚花，直接上高脚\n3. 最后一步 deadpoint 到大圆 sloper，注意核心收紧\n试了很多方法这个最省力，希望有帮助！",
            PostType.GENERAL, true, "月石 Blue V5", 18, 6, now.minusDays(2).minusHours(2));

        Post p9  = post(mike,
            "周末去太湖石公园外岩了，线路条件很好，这个季节岩石干燥摩擦力好。推荐「猴子抱树」5.10b，适合带初学者练置绳。有车的朋友可以约！",
            PostType.GENERAL, false, null, 25, 4, now.minusDays(3));

        Post p10 = post(dada,
            "Campus Wall 新出了一条 V9！路线设置师说灵感来自 Alban Levier 的风格，动态很多，体力消耗大。第一步就要 dyno 上大 jug，之后全是小 crimp……有人一起研究 beta 吗？",
            PostType.GENERAL, true, "Campus Wall V9 新线", 19, 5, now.minusDays(3).minusHours(5));

        Post p11 = post(lisa,
            "第一次 Flash 了一条 V3，超级开心！！虽然对大家来说很简单哈哈，但对我来说是个里程碑。谢谢上周带我的大毛哥 🐼",
            PostType.GENERAL, false, null, 42, 8, now.minusDays(4));

        Post p12 = post(tom,
            "路线设置小 tip：slab 路线里脚点的角度比你想象的更重要。稍微向外旋转 5° 会让路线变得更 technical 也更有趣。欢迎挑战本周的新 slab！",
            PostType.GENERAL, false, null, 13, 2, now.minusDays(5));

        // ── Comments ──────────────────────────────────────────────────────────

        // p1 — Jay's V6 flash
        cmt(dada,  p1, "Congrats! That sidepull is sneaky. Most people try to reach past it first attempt.", now.minusHours(1).minusMinutes(45));
        cmt(sarah, p1, "I've been trying that one too! Will try the sidepull beta next session 🙏", now.minusHours(1).minusMinutes(20));
        cmt(lisa,  p1, "So inspiring!! Can't wait to get to V6 one day haha", now.minusMinutes(50));

        // p2 — Sarah find partner
        cmt(lisa,  p2, "Me!! I'm only V4 but I'd love to join 😊", now.minusHours(4).minusMinutes(30));
        cmt(jay,   p2, "I might drop by Saturday afternoon too, let's connect!", now.minusHours(3));

        // p3 — Mike V7 beta
        cmt(dada,  p3, "Confirmed — the blue hold is definitely a trap 😂 took me 4 tries to realize it", now.minusDays(1).plusMinutes(30));
        cmt(jay,   p3, "The deadpoint to the sloper is so satisfying when it works. Nice beta!", now.minusDays(1).plusHours(1));
        cmt(tom,   p3, "I set that one! Glad someone cracked it 🙌 the blue hold was intentionally cheeky lol", now.minusDays(1).plusHours(2));
        cmt(sarah, p3, "Added to my project list, thanks Mike!", now.minusDays(1).plusHours(3));
        cmt(mike,  p3, "Good luck everyone — took me way longer than I'd like to admit 😅", now.minusDays(1).plusHours(4));

        // p6 — 大毛 V8 send
        cmt(jay,   p6, "兄弟牛啊！！！那条我做了三次还没送，等你教我旗步怎么用 😭", now.minusDays(1).plusMinutes(10));
        cmt(sarah, p6, "恭喜！！你说的旗步我理解不了，下次遇到能不能给我示范一下？", now.minusDays(1).plusMinutes(25));
        cmt(dada,  p6, "下次去馆的时候随时喊我，帮你们看看 beta！", now.minusDays(1).plusMinutes(40));
        cmt(lisa,  p6, "V8 对我来说完全是天文数字……大毛哥超厉害！", now.minusDays(1).plusHours(1));
        cmt(tom,   p6, "旗步是那条路线的关键，我设的时候就预设了这个 intention 💪", now.minusDays(1).plusHours(2));
        cmt(mike,  p6, "那条我还没试过，下周去看看！", now.minusDays(1).plusHours(3));
        cmt(jay,   p6, "已经约好了周六，一起研究！", now.minusDays(1).plusHours(4));

        // p7 — Lisa find partner
        cmt(sarah, p7, "我周六下午在！可以一起，我也在练 V4~V5 🙌", now.minusHours(7));
        cmt(dada,  p7, "我可能会在，到时候见！V3 做好了快去挑战 V4", now.minusHours(6));
        cmt(lisa,  p7, "太好了谢谢大家！到时候馆里见 🥳", now.minusHours(5));

        // p8 — Sarah V5 beta
        cmt(mike,  p8, "高脚那步我每次都很犹豫，试试你说的直接上！", now.minusDays(2).plusHours(1));
        cmt(dada,  p8, "这条我做了，deadpoint 那步核心要发力不然会砸下来 👍", now.minusDays(2).plusHours(2));
        cmt(jay,   p8, "月石那条我上次去没看到，下次专门找找", now.minusDays(2).plusHours(3));
        cmt(tom,   p8, "Beta 分享赞！这种帖子希望多一些", now.minusDays(2).plusHours(4));
        cmt(sarah, p8, "大家加油！有问题随时问我", now.minusDays(2).plusHours(5));
        cmt(lisa,  p8, "V5 对我来说还遥不可及……慢慢来 😅", now.minusDays(2).plusHours(6));

        // p11 — Lisa first V3 flash
        cmt(dada,  p11, "哈哈带你是应该的！继续加油，下次挑战 V4 💪", now.minusDays(4).plusHours(1));
        cmt(jay,   p11, "第一次 Flash 的感觉最棒了，以后会越来越多的！", now.minusDays(4).plusHours(2));
        cmt(sarah, p11, "恭喜！！V3 Flash 也是 Flash，没有什么「只是」😊", now.minusDays(4).plusHours(3));
        cmt(tom,   p11, "这种里程碑的感觉会一直激励你的 🎉", now.minusDays(4).plusHours(4));
        cmt(mike,  p11, "加油！很快就会 Flash V4 了", now.minusDays(4).plusHours(5));
        cmt(sarah, p11, "下次一起！", now.minusDays(4).plusHours(6));
        cmt(dada,  p11, "来来来 V4 等你 😆", now.minusDays(4).plusHours(7));

        log.info("[Community] Seeded 6 demo users, {} posts, {} comments.",
                postRepository.count(), commentRepository.count());
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private User save(String name, String email, String pw, String city, String bio) {
        return userRepository.findByEmailIgnoreCase(email).orElseGet(() ->
            userRepository.save(User.builder()
                .name(name).email(email).passwordHash(pw)
                .role(UserRole.CLIMBER).city(city).bio(bio)
                .build()));
    }

    private Post post(User author, String content, PostType type, boolean isBeta,
                      String routeName, int likes, int comments, LocalDateTime createdAt) {
        Post p = postRepository.save(Post.builder()
            .user(author).content(content).type(type)
            .isBeta(isBeta).routeName(routeName)
            .likeCount(likes).commentCount(comments)
            .build());
        postRepository.flush();
        em.createNativeQuery("UPDATE posts SET created_at = ? WHERE id = ?")
            .setParameter(1, createdAt)
            .setParameter(2, p.getId())
            .executeUpdate();
        return p;
    }

    private void cmt(User author, Post post, String content, LocalDateTime createdAt) {
        Comment c = commentRepository.save(Comment.builder()
            .user(author).post(post).content(content).build());
        commentRepository.flush();
        em.createNativeQuery("UPDATE comments SET created_at = ? WHERE id = ?")
            .setParameter(1, createdAt)
            .setParameter(2, c.getId())
            .executeUpdate();
    }
}
