# Game Concept: Realms of the Forgotten

*Created: 2026-03-21*
*Status: Draft*

---

## Elevator Pitch

> It's a solo third-person RPG where you explore a vast, WoW-inspired world with
> zone-based storytelling, cinematic questlines, deep class systems, and unlimited
> professions — designed so every piece of content is completable alone, pausable
> at any moment, and always rewarding. Like classic WoW, but built from the ground
> up for one player with a controller on the couch.

---

## Core Identity

| Aspect | Detail |
| ---- | ---- |
| **Genre** | Third-person action RPG with MMO-style progression and zone structure |
| **Platform** | PC (Laptop), iPad (with controller), Nintendo Switch |
| **Target Audience** | Solo RPG players who love WoW's world but not its group requirements |
| **Player Count** | Single-player only |
| **Session Length** | 30 min - 2+ hours (fully pausable, including cutscenes) |
| **Monetization** | TBD (premium + expansions likely; no subscription, no FOMO) |
| **Estimated Scope** | Very Large (ongoing live-service, expandable indefinitely) |
| **Comparable Titles** | World of Warcraft (solo questing), Skyrim, The Witcher 3, FFXIV (Trust system) |

---

## Core Fantasy

You are a lone hero in a vast, living world — not because you're antisocial, but
because this world was built for *you*. Every quest, every dungeon, every epic
storyline was designed to be experienced by one person at their own pace. You
master every craft, shape the fate of kingdoms through your choices, and build a
homestead that reflects your journey. The world remembers what you've done, and
no one can take that away.

This is the WoW you always wanted to play alone — with all the depth, none of
the friction, and a controller in your hands.

---

## Unique Hook

Like classic World of Warcraft's epic zone-based storytelling and deep class
systems, AND ALSO every system is solo-first with Witcher-style consequential
choices that permanently reshape the world, unlimited profession mastery on a
single character, and a controller-native interface designed for couch play.

No other game combines MMO-depth progression with true solo design. Every
"solo-friendly MMO" is still an MMO with solo bolted on. This is the reverse:
a solo RPG with MMO-depth systems built in from day one.

---

## Player Experience Analysis (MDA Framework)

### Target Aesthetics (What the player FEELS)

| Aesthetic | Priority | How We Deliver It |
| ---- | ---- | ---- |
| **Sensation** (sensory pleasure) | 4 | AI-assisted realistic visuals, adaptive music, satisfying combat feedback |
| **Fantasy** (make-believe, role-playing) | 1 | Deep class identity, epic questlines, "you are the hero" narrative |
| **Narrative** (drama, story arc) | 2 | Cinematic cutscenes, consequential choices, zone-spanning story arcs |
| **Challenge** (obstacle course, mastery) | 5 | Ability rotation mastery, scaling difficulty, optional hard content |
| **Fellowship** (social connection) | N/A | Solo game — no multiplayer systems |
| **Discovery** (exploration, secrets) | 3 | Open world exploration, hidden areas, lore collectibles, profession recipes |
| **Expression** (self-expression, creativity) | 6 | Character builds, homestead customization, all-profession mastery |
| **Submission** (relaxation, comfort zone) | 7 | Pausable everything, no FOMO, play at your pace |

### Key Dynamics (Emergent player behaviors)

- Players will experiment with class ability combinations to find optimal rotations
- Players will return to completed zones to see how their choices changed the world
- Players will set personal goals around profession mastery and homestead building
- Players will replay questlines differently to see alternate outcomes
- Players will push into harder content as their mastery deepens

### Core Mechanics (Systems we build)

1. **Ability rotation combat** — WoW-style cooldown-based combat adapted for
   gamepad with soft lock-on targeting and resource builder/spender systems
2. **Zone-based quest progression** — Each zone tells a self-contained epic story
   with branching choices and cinematic cutscenes
3. **Class and mastery system** — Multiple classes learnable on one character,
   with soft-capped core stats and infinitely deepening mastery trees
4. **Profession and crafting system** — All professions available to one character,
   deep recipe trees, gathering + crafting + building
5. **World-state persistence** — Player choices permanently alter zones, NPCs,
   and available content

---

## Player Motivation Profile

### Primary Psychological Needs Served

| Need | How This Game Satisfies It | Strength |
| ---- | ---- | ---- |
| **Autonomy** (freedom, meaningful choice) | Choose your class, your professions, your path through zones, your story choices. No gates, no caps, no forced content. | Core |
| **Competence** (mastery, skill growth) | Rotation mastery, profession depth, mastery trees that always expand. Soft cap means old zones feel powerful, new zones still challenge. | Core |
| **Relatedness** (connection, belonging) | Connection to the world, its characters, and the homestead you build. NPC relationships and story investment replace player-to-player bonds. | Supporting |

### Player Type Appeal (Bartle Taxonomy)

- [x] **Achievers** (goal completion, collection, progression) — How: Infinite
  mastery progression, profession completion, zone completion, homestead building
- [x] **Explorers** (discovery, understanding systems, finding secrets) — How:
  Open world with hidden areas, lore, secret recipes, and alternate quest paths
- [ ] **Socializers** (relationships, cooperation, community) — N/A: Solo game.
  NPC relationships provide a narrative substitute.
- [ ] **Killers/Competitors** (domination, PvP, leaderboards) — N/A: No PvP,
  no competitive systems.

### Flow State Design

- **Onboarding curve**: Class-specific opening questline (like WoW's DK starting
  zone) teaches abilities one at a time through narrative, not tutorials. Each
  new ability is introduced via a quest that requires using it.
- **Difficulty scaling**: Zones have suggested power levels. Enemies scale with
  mastery within a zone but not across zones — old zones feel powerful, new zones
  challenge. Optional "hard mode" encounters for mastery-hungry players.
- **Feedback clarity**: Damage numbers, ability proc indicators, quest objective
  tracking, profession skill-up notifications. Constant micro-rewards.
- **Recovery from failure**: Respawn at nearest waypoint with no XP/item loss.
  Death is a "try again" moment, not a punishment. Bosses have checkpoint phases.

---

## Core Loop

### Moment-to-Moment (30 seconds)
Engage enemies using ability rotation — builders generate resources, spenders
consume them for powerful effects, cooldowns create rhythm. Soft lock-on targeting
with gamepad. Dodge/reposition between ability casts. Loot drops automatically
collected. The rotation itself should feel satisfying even without rewards — the
rhythm of a well-played rotation IS the fun.

### Short-Term (5-15 minutes)
Accept quest from NPC or quest board. Travel through zone, encountering enemies,
gathering nodes, environmental storytelling. Complete quest objective (kill boss,
rescue NPCs, make story choice, solve environmental puzzle). Watch cutscene or
receive story payoff. Earn XP, materials, and ability/mastery progress. Pick up
next quest in the chain.

### Session-Level (30-120 minutes)
Progress through a zone's main questline (3-5 quests per session). Unlock new
abilities or mastery nodes from leveling. Gather materials during travel. Return
to homestead to craft, build, and organize. See the consequences of story choices
reflected in the world (village rebuilt, faction banner changed, NPC alive or
dead). Discover the hook for the next zone or questline. Natural stopping point:
completion of a quest chain chapter.

### Long-Term Progression
- Class mastery deepens with new ability variants and synergies
- Profession trees expand with increasingly complex recipes and rare materials
- Homestead grows from a campfire to an estate with workshops, gardens, displays
- World state evolves based on accumulated choices across zones
- New zones, classes, and content added via expansions (modular architecture)
- No level cap — mastery trees always have a next node to unlock

### Retention Hooks
- **Curiosity**: What happens in the next zone? What's behind that locked door?
  What does the legendary recipe create? How does my choice affect the ending?
- **Investment**: My character has mastered 3 classes and 6 professions. My
  homestead has a trophy room. The village I saved in zone 2 is thriving.
- **Social**: N/A (solo game — retention is intrinsic, not obligation-based)
- **Mastery**: I can feel my rotation getting smoother. The hard-mode boss that
  killed me last session is beatable now. New mastery nodes opened up a build
  I want to try.

---

## Game Pillars

### Pillar 1: Your Journey, Your Pace
Every piece of content is completable solo, pausable at any moment, and respects
the player's time. No group requirements, no FOMO timers, no content that
punishes you for playing less.

*Design test*: "Should this dungeon require a party?" — No. Scale it for solo
with optional AI companions if needed.

### Pillar 2: Always Something New
The player should never hit a wall where progression stops. Soft-capped stats,
infinite mastery depth, ever-expanding profession trees, and new abilities ensure
there's always a next thing to chase.

*Design test*: "Should we add a level cap?" — No. Add a new mastery branch instead.

### Pillar 3: Choices Shape the World
Player decisions have visible, lasting consequences. Villages are saved or lost.
Factions rise or fall. The world you see at hour 100 should be different from
another player's world at hour 100.

*Design test*: "Should this quest have one outcome?" — No. Give at least two
paths with different world-state results.

### Pillar 4: Master of All Trades
One character can learn every class, every profession, every skill. No artificial
restrictions forcing alts or respecs. The player's investment in their character
is never wasted.

*Design test*: "Should we lock professions to 2 per character?" — No. Let them
learn everything.

### Pillar 5: Couch-Ready Controller Experience
Every system must work flawlessly with a gamepad. If it can't be operated with a
controller on a couch, it needs redesigning. UI, menus, combat, crafting — all
controller-first.

*Design test*: "Should this crafting menu use mouse-driven drag-and-drop?" — No.
Radial or grid navigation with controller support.

### Pillar 6: Epic Storytelling at Every Turn
Every zone, every class, every major profession has a rich narrative with
cinematic cutscenes, memorable characters, and dramatic arcs. Quests are chapters
in an epic story, not checklists. The WoW Death Knight starting zone and Warlock
pet quests are the baseline quality, not the exception.

*Design test*: "Can we skip the cutscene budget on this quest chain and just use
text boxes?" — No. If it's a major questline, it gets cinematics.

### Anti-Pillars (What This Game Is NOT)

- **NOT multiplayer**: No PvP, no co-op, no group requirements. Social features
  are simulated through NPC companions and world-state, never real players.
- **NOT a grind**: Progression comes from quests, exploration, and crafting — not
  repeating the same content for drops. Respect the player's time.
- **NOT punishing**: Death is a setback, not a punishment. No permadeath, no
  harsh corpse runs, no significant loss of progress.
- **NOT FOMO-driven**: No daily quests, no time-limited events, no "log in today
  or miss out." The world waits for you.
- **NOT a fetch-quest factory**: No "kill 10 wolves" padding. Every quest serves
  the narrative or teaches a mechanic. If a quest doesn't advance story,
  character, or world-state, it doesn't ship.

---

## Inspiration and References

| Reference | What We Take From It | What We Do Differently | Why It Matters |
| ---- | ---- | ---- | ---- |
| World of Warcraft (Classic/WotLK) | Zone progression, class fantasy quests, talent trees, profession breadth, ability rotations | Solo-first design, no group content, no caps, all professions on one character | Validates the core appeal — millions played WoW solo despite it being an MMO |
| The Witcher 3 | Consequential story choices, cinematic quests, mature narrative | WoW-style class systems and progression depth instead of fixed character | Validates story-driven open RPG market (50M+ copies) |
| Skyrim / Elder Scrolls | Open world freedom, player housing (Hearthfire), learn-everything character | Structured zone progression alongside open exploration, deeper class systems | Validates solo open-world RPG with crafting (60M+ copies) |
| FFXIV (Trust System) | Proof that MMO content can work solo, cross-hotbar controller UI | Built solo-first from day one, not retrofitted | Validates demand — Square Enix invested heavily in making their MMO soloable |
| God of War (2018) | Gamepad combat feel, cinematic presentation, father-son narrative | Ability rotation instead of combo-based, open world instead of linear | Validates controller-first RPG with deep combat and story |
| Assassin's Creed (Valhalla/Odyssey) | Open world with settlement building, RPG progression, historical setting | Deeper class/profession systems, more consequential choices | Validates open-world RPG with base-building elements |
| Starfield / Fallout 4 | Settlement building, crafting depth, world-shaping choices | Fantasy setting, WoW-style progression instead of Bethesda-style | Validates player desire to build and shape the world |

**Non-game inspirations**: Lord of the Rings (epic fantasy scale and stakes),
classic D&D campaigns (class identity and character building), Studio Ghibli
films (sense of wonder in exploring new places).

---

## Target Player Profile

| Attribute | Detail |
| ---- | ---- |
| **Age range** | 25-45 |
| **Gaming experience** | Mid-core to hardcore RPG players |
| **Time availability** | Variable — 30-minute sessions on weeknights, longer on weekends. The game must accommodate both. |
| **Platform preference** | Couch play with controller (PC, iPad, Switch) |
| **Current games they play** | WoW Classic, Skyrim, Witcher 3, FFXIV, Assassin's Creed, God of War |
| **What they're looking for** | The MMO experience without the MMO obligations — deep progression, epic stories, endless content, but on their terms |
| **What would turn them away** | Group requirements, FOMO mechanics, grind-heavy progression, poor controller support, shallow storytelling |

---

## Technical Considerations

| Consideration | Assessment |
| ---- | ---- |
| **Engine** | Godot 4.6 + Godogen (vibe-coding workflow) |
| **Key Technical Challenges** | World streaming (large zones), save system (world-state persistence with branching choices), ability rotation system on gamepad (cross-hotbar or modifier system), AI texture pipeline consistency, Switch performance targets |
| **Art Style** | AI-assisted realistic — AI-generated textures + curated asset store models, post-processed for visual cohesion |
| **Art Pipeline Complexity** | Medium — AI generation speeds production but requires curation passes and an art bible for consistency |
| **Audio Needs** | Adaptive — zone music with combat transitions, ambient environmental audio, voice acting for major cutscenes and key NPCs |
| **Cutscene System** | Hybrid — in-engine cinematics for epic story moments, portrait/dialogue system for regular quests. Both fully pausable. |
| **Networking** | None (single-player only) |
| **Content Volume** | Launch target: 3-5 zones, 3 classes, 5+ professions, 20+ hours. Designed for indefinite expansion. |
| **Procedural Systems** | Minimal — hand-crafted zones and quests. Potentially procedural gathering node placement and minor ambient encounters. |

---

## Risks and Open Questions

### Design Risks
- WoW-style ability rotation on a gamepad may feel clunky without extensive UX
  iteration — this is the highest priority prototype target
- "No caps" progression needs a compelling power curve that avoids both
  trivialization (too powerful) and stagnation (growth too slow to feel)
- Consequential choices create combinatorial world-states that are expensive to
  author and test
- Solo dungeons need to be engaging without group dynamics — encounter design
  must compensate for missing roles (tank/healer/DPS)

### Technical Risks
- World-state persistence with branching choices requires a robust save system
  that tracks hundreds of flags without save file bloat
- Large open zones on Switch/iPad may require aggressive LOD and streaming
- AI-generated art assets may lack visual cohesion without a strong post-processing
  pipeline and art direction
- Godogen is a new tool — its suitability for large-scale architecture is unproven

### Market Risks
- "Solo WoW" may sound niche despite the massive audience of solo MMO players
- Competing with polished AAA titles (Witcher, Elder Scrolls) on production
  values as a solo dev is a perception challenge
- Live-service model as a solo dev requires sustainable content pipeline

### Scope Risks
- This is genuinely one of the most ambitious solo dev projects possible —
  strict scope discipline is critical
- Content volume ("always something new") is the hardest promise to keep
- Cinematic cutscenes for every major questline is expensive even with hybrid approach
- Every new class multiplies the testing and balance surface

### Open Questions
- How exactly should the gamepad ability bar work? (FFXIV cross-hotbar vs ESO
  5-slot vs custom solution) — **needs prototyping**
- How do solo dungeons maintain tension without group roles? (Companion AI?
  Encounter redesign? Player multi-role?) — **needs design exploration**
- What's the right power curve for "no caps" that still feels rewarding at
  hour 200? — **needs math modeling**
- How do we maintain art consistency across AI-generated assets? — **needs
  pipeline prototyping**
- How does Godogen fit into a large-scale, modular architecture? — **needs
  research and validation**

---

## MVP Definition

**Core hypothesis**: Players find the WoW-style ability rotation engaging on a
gamepad, and the quest-driven zone progression with story choices keeps them
playing for 30+ minute sessions.

**Required for MVP**:
1. One playable class with 6-8 abilities mapped to gamepad
2. One zone with a 2-3 hour questline including at least one branching choice
3. Basic combat with ability rotation, soft lock-on, and enemy encounters
4. Quest system with objectives, dialogue, and at least one in-engine cutscene
5. One world-state change visible after a quest choice
6. Basic crafting (1 gathering + 1 crafting profession)
7. Pause anywhere (including mid-cutscene)

**Explicitly NOT in MVP** (defer to later):
- Multiple classes
- Homestead building
- Full profession system
- Multiple zones
- Mastery trees
- Advanced world-state branching

### Scope Tiers

| Tier | Content | Features | Goal |
| ---- | ---- | ---- | ---- |
| **MVP** | 1 zone, 1 class, 1 questline | Core combat, basic questing, 1 crafting loop | "Is the core loop fun on a gamepad?" |
| **Vertical Slice** | 1 complete zone with full story + cutscenes | 1 class fully realized, homestead basics, 3 professions | "Does a full session feel right?" |
| **Alpha** | 3 zones, 3 classes, full profession suite | All core systems, world-state choices, homestead | "Can I play this for 20 hours?" |
| **Full Vision** | 5+ zones, 5+ classes, deep professions | Complete narrative arcs, full homestead, expansion pipeline | Ongoing live service |

---

## Next Steps

- [ ] Configure engine and platform targets (`/setup-engine godot 4.6`)
- [ ] Validate concept completeness (`/design-review design/gdd/game-concept.md`)
- [ ] Decompose concept into individual systems (`/map-systems`)
- [ ] Research Godogen for large-scale architecture suitability
- [ ] Create first architecture decision record (`/architecture-decision`)
- [ ] Prototype core loop: 1 class, gamepad combat, 1 zone (`/prototype combat`)
- [ ] Validate core loop with playtest (`/playtest-report`)
- [ ] Plan first milestone (`/sprint-plan new`)
