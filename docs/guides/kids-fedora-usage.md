# Kids' Fedora Learning Environment - Parent's Usage Guide

**Target Audience**: Parents of children ages 4-12
**Purpose**: Comprehensive guide for managing a safe, educational Fedora environment
**Created**: 2025-10-26
**Last Updated**: 2025-10-26

---

## 🎯 Quick Start (5 Minutes)

### First Time Setup Complete?

If you just ran `kids-fedora-bootstrap.sh`, complete these critical steps:

1. **Set Time Limits** (5 min):
   ```bash
   malcontent-control
   ```
   - Select your child's account
   - Set daily time limit (recommended: 2-3 hours for ages 4-12)
   - Set allowed hours (e.g., 9 AM - 7 PM, no late-night usage)

2. **Configure DNS Filtering** (3 min):
   - Parallels: VM Configuration → Hardware → Network → Advanced → DNS
   - Primary DNS: `208.67.222.123` (OpenDNS FamilyShield)
   - Secondary DNS: `208.67.220.123`

3. **Test Everything** (10 min):
   - Log in as your child
   - Try launching educational apps
   - Test that inappropriate sites are blocked
   - Verify time limits trigger warnings

4. **Take Snapshot** (2 min):
   - Parallels: Actions → Take Snapshot
   - Name: "Initial Setup Complete - [Date]"

---

## 📚 Educational Philosophy

### Why This Approach Works

**Five Layers of Protection:**

1. **Layer 1: User Account Restrictions**
   - Your child CANNOT install software
   - No access to system settings
   - No sudo/administrator privileges
   - File access limited to their home directory

2. **Layer 2: Parental Controls (Malcontent)**
   - System-level app restrictions
   - Time-based access control
   - Age-appropriate content filtering (OARS ratings)
   - Centrally managed via malcontent-control GUI

3. **Layer 3: Network DNS Filtering**
   - Blocks inappropriate websites at network level
   - Works across all apps (browser, chat, etc.)
   - Cannot be bypassed by kids
   - OpenDNS FamilyShield or Cloudflare for Families

4. **Layer 4: Browser Safety**
   - Firefox extensions (uBlock Origin, LeechBlock)
   - Kid-friendly homepage (PBS Kids)
   - Private browsing disabled
   - Strict tracking protection

5. **Layer 5: Physical Supervision**
   - Your presence and guidance
   - Teaching digital citizenship
   - Reviewing activities together
   - Building trust through transparency

### Screen Time Best Practices

**Recommended Daily Limits by Age:**
- Ages 4-6: 1-2 hours (supervised)
- Ages 6-8: 2-3 hours (supervised initially, gradual independence)
- Ages 8-10: 2-4 hours (check-ins, increasing independence)
- Ages 10-12: 3-5 hours (responsible independence, monitoring)

**Balance is Key:**
- Mix educational content (70%) with creative/fun time (30%)
- Encourage outdoor play and physical activity
- No screens 1 hour before bedtime
- Family device-free times (meals, etc.)

---

## 📱 Daily Operations

### Morning Setup (5 Minutes)

**Before your child logs in:**

```bash
# Check yesterday's usage
sudo kids-dashboard

# Review activity logs
sudo tail -20 /var/log/kids-usage.log

# Verify time limits are set
malcontent-client get [child-username]
```

**Quick Health Check:**
```bash
# Verify kids' account has NO sudo
groups [child-username]  # Should NOT see wheel/sudo

# Check malcontent service is running
systemctl status malcontent-accounts.service

# Verify disk space
df -h /home
```

### During Usage

**Ages 4-6 (Close Supervision):**
- Stay in the same room
- Help navigate apps
- Explain what they're learning
- Limit to 30-minute sessions

**Ages 6-8 (Periodic Check-ins):**
- Check in every 15-20 minutes
- Ask what they're working on
- Be available for questions
- Review completed activities

**Ages 8-12 (Increasing Independence):**
- Visible presence (same floor/nearby)
- Check in every 30 minutes
- Review work at end of session
- Encourage self-directed learning

### Evening Wind-Down (5 Minutes)

**Review Together:**
```bash
# View today's dashboard
sudo kids-dashboard
```

**Discussion Questions:**
- What did you learn today?
- What was your favorite activity?
- Did you have any problems?
- What would you like to do tomorrow?

**Educational Reflection:**
- Celebrate accomplishments
- Connect learning to real life
- Set goals for next session

---

## 🔧 Weekly Maintenance (15 Minutes)

### Sunday Evening Routine

**1. System Updates** (10 min):
```bash
# Update Fedora packages
sudo dnf update

# Reboot if kernel updated
sudo systemctl reboot
```

**2. Review Full Week** (5 min):
```bash
# Weekly dashboard
sudo kids-dashboard

# Check for patterns
grep "$(date -d '7 days ago' '+%Y-%m-%d')" /var/log/kids-usage.log | less
```

**3. Adjust Settings**:
- Time limits (increase/decrease based on behavior)
- App restrictions (add new approved apps)
- Content filtering (adjust if needed)

**4. Disk Space Check**:
```bash
# Check storage
du -sh /home/[child-username]

# Clean if needed (with child)
cd /home/[child-username]
rm -rf .cache/*  # Clear application caches
```

---

## 📊 Monthly Health Checks (30 Minutes)

### Monthly Review Checklist

**Educational Progress:**
- [ ] Review what skills were practiced most
- [ ] Identify learning gaps
- [ ] Add software for underutilized subjects
- [ ] Remove apps that aren't engaging

**Software Effectiveness:**
- [ ] Which apps were used most? (kids-dashboard)
- [ ] Which apps were ignored?
- [ ] Are apps age-appropriate?
- [ ] Need to add new challenges?

**Safety Verification:**
```bash
# Verify sudo restrictions still in place
sudo -u [child-username] sudo -n true
# Should output: "sudo: a password is required"

# Check group membership
groups [child-username]
# Should NOT include: wheel, sudo, admin

# Verify malcontent is active
systemctl is-active malcontent-accounts.service
```

**Backup and Snapshots:**
- [ ] Take monthly Parallels snapshot
- [ ] Name: "Monthly-[YYYY-MM]"
- [ ] Keep last 3 months
- [ ] Test restore if needed

**Age-Appropriate Adjustments:**
- [ ] Review content filters (OARS level)
- [ ] Adjust time limits
- [ ] Add more independence (if earned)
- [ ] Update app restrictions

---

## 🎓 Teaching Moments

### First Login: Password Education

**Make it a learning experience:**

```bash
# Child's first login (after you set initial password)
# They'll be prompted to change it
```

**Teach:**
- Why passwords matter (protect your work)
- What makes a good password (long, memorable, unique)
- Never share passwords (except with parents)
- How to remember passwords (phrase, not random)

**Example Good Password for Kids:**
- "MyDog'sName is Buddy123!" (memorable, complex)
- "ILove2DrawInTuxPaint!" (personal, secure)

### Time Limits: Healthy Habits

**When discussing limits:**

✅ **DO Say:**
- "Time limits help us balance screen time with other activities"
- "They help protect your eyes and keep you healthy"
- "We all have limits (I do too!)"
- "You can earn extra time for special projects"

❌ **DON'T Say:**
- "You're addicted to screens"
- "I don't trust you"
- "This is punishment"

**Earning Extra Time:**
- Completed homework
- Special educational project
- Weekend family activity
- Good behavior all week

### Monitoring: Building Trust

**Be Transparent:**

```bash
# Show them the dashboard together
sudo kids-dashboard

# Explain what you see
"Look, you spent 2 hours on GCompris this week - great job learning math!"
"I see you tried Firefox 10 times - what were you looking for?"
```

**Build Trust:**
- Explain logs exist (but you're not spying)
- Review together weekly
- Celebrate good choices
- Discuss concerns openly

### Online Safety Conversations

**Age-Appropriate Discussions:**

**Ages 4-6:**
- "Some websites are for grown-ups, not kids"
- "Always ask parent before clicking links"
- "If something scary appears, get me immediately"

**Ages 6-8:**
- "Internet can be helpful and fun, but has dangers"
- "Never share personal information (name, address, school)"
- "If someone asks where you live, tell parent right away"

**Ages 8-10:**
- "Not everyone online is who they say they are"
- "It's okay to say no to uncomfortable requests"
- "Screenshots last forever - think before posting"

**Ages 10-12:**
- "Digital footprint is permanent"
- "Cyberbullying is real - be kind online"
- "If friends pressure you to do something unsafe online, talk to me"

---

## 🔍 Monitoring Without Invading Privacy

### Age-Appropriate Boundaries

**Ages 4-6: Full Visibility**
- Review everything together
- Direct supervision always
- No expectation of privacy
- Learning what's appropriate

**Ages 6-8: Supervised Independence**
- Review daily summaries
- Spot-check browser history
- Ask about their day
- Building judgment

**Ages 8-10: Guided Independence**
- Weekly dashboard reviews
- Monthly deep-dive
- Trust, but verify
- Teaching responsibility

**Ages 10-12: Responsible Independence**
- Monthly reviews together
- Check only if concerns arise
- Respect growing privacy
- Prepare for teen years

### The "Transparency Pact"

**Establish Rules Together:**

1. "I will check your activity regularly" (honesty)
2. "You can always ask me about anything you see online" (open door)
3. "Mistakes happen - talk to me, no punishment for honesty" (safe space)
4. "Privacy grows with responsibility" (incentive)

### Red Flags to Watch For

**Behavioral Changes:**
- Suddenly secretive about screen time
- Quickly closing apps when you approach
- Defensive about time limits
- Loss of interest in outdoor/social activities

**Usage Patterns:**
- Excessive time in one app (obsession)
- Late-night usage attempts
- Trying to bypass filters
- Deleting browser history frequently

**If You See Concerns:**
1. Don't panic or punish immediately
2. Have calm, curious conversation
3. Understand the "why" behind behavior
4. Adjust settings if needed
5. Seek professional help if serious

---

## 🎮 Educational Software Guide

### By Age and Subject

#### Ages 4-6: Foundation Skills

**Math & Numbers:**
- **GCompris** - Click on "Math" activities
  - Number sequence (1-10)
  - Simple addition
  - Shapes and patterns
- **Tux Math** - Easier levels only
  - Falling numbers game
  - Start with single digits

**Reading & Language:**
- **GCompris** - Reading activities
  - Letter recognition
  - Phonics games
  - Simple words
- **KHangMan** - Very easy mode
  - Picture-based words

**Creative Expression:**
- **Tux Paint** - Supervised
  - Free drawing
  - Stamps and effects
  - Save artwork to ~/Pictures
- **Ktuberling** - Picture game
  - Drag and drop fun

**Logic & Problem Solving:**
- **GCompris** - Puzzle activities
  - Memory games
  - Pattern matching
  - Simple mazes

#### Ages 6-8: Building Confidence

**Math:**
- **GCompris** - Intermediate math
  - Addition/subtraction (two digits)
  - Multiplication introduction
  - Money concepts
- **Tux Math** - Medium difficulty
- **Gbrainy** - Number games

**Reading:**
- **GCompris** - Reading comprehension
- **Calibre** - E-book reader
  - Load age-appropriate books
- **KWordQuiz** - Vocabulary building

**Typing:**
- **Tux Typing** - Essential skill!
  - Start with home row
  - Progress to full keyboard
  - Make it daily routine (10 min/day)
- **Klavaro** - Touch typing tutor

**Science:**
- **Marble** - Geography explorer
  - Find continents
  - Locate countries
  - Learn capitals
- **Stellarium** - Night sky
  - Identify constellations
  - Learn planet names

#### Ages 8-10: Deeper Learning

**Math & Logic:**
- **GCompris** - Advanced math
  - Multiplication tables
  - Division
  - Fractions
- **KBruch** - Fraction practice
- **Kalgebra** - Algebra introduction
- **GNOME Chess** - Strategy thinking

**Programming:**
- **Scratch** - Visual programming
  - Start with tutorials
  - Create simple games
  - Remix existing projects
- **Python + Turtle Graphics**
  - Simple drawing programs
  - Text-based adventures

**Science:**
- **Stellarium** - Deep sky objects
- **Celestia** - Space simulation
  - Visit planets
  - Learn about solar system
- **Kalzium** - Chemistry
  - Periodic table
  - Element properties

**Creative:**
- **Inkscape** - Vector graphics
  - Trace drawings
  - Create logos
  - Design posters
- **GIMP** - Photo editing
  - Basic adjustments
  - Filters and effects
- **MuseScore** - Music composition
  - Simple melodies
  - Read music notation

#### Ages 10-12: Advanced Skills

**Programming:**
- **Python** - Text-based coding
  - Variables and loops
  - Functions
  - Simple games
- **Scratch** - Advanced projects
  - Multi-sprite games
  - Variables and logic
  - Share with community

**Creative Professional Tools:**
- **GIMP** - Advanced editing
- **Inkscape** - Design projects
- **Audacity** - Audio editing
  - Record voice
  - Edit music
  - Create podcasts
- **MuseScore** - Full compositions

**Research & Writing:**
- **LibreOffice Writer** - Essays
- **Calibre** - E-book management
- **Firefox** - Research (supervised)

**Advanced Science:**
- **Stellarium** - Astronomy deep-dive
- **R** - Data visualization (intro)
- **Jupyter Lab** - Science notebooks

### Learning Progression Tips

**Start Easy, Build Confidence:**
1. Begin with apps they master quickly
2. Celebrate small wins
3. Gradually increase difficulty
4. Don't rush progression

**Mix Learning Styles:**
- Visual: Tux Paint, Marble, Stellarium
- Auditory: Music apps, language tools
- Kinesthetic: Interactive games
- Logical: Programming, chess

**Connect to School:**
- Supplement homework topics
- Practice skills ahead of class
- Reinforce weak areas
- Extend advanced learners

---

## 🚨 Troubleshooting

### Common Issues and Solutions

#### Issue: Time Limits Not Working

**Symptoms:**
- Child can use computer past set time limit
- No warning before timeout
- Account not locking

**Solutions:**
```bash
# 1. Check malcontent service
systemctl status malcontent-accounts.service

# If not running:
sudo systemctl restart malcontent-accounts.service

# 2. Verify time limits are set
malcontent-client get [child-username]

# 3. Re-apply limits
malcontent-control
# Select child, re-set time limits, Apply

# 4. Log out and log back in (child account)
```

#### Issue: Child Has Sudo Access

**CRITICAL SAFETY ISSUE!**

**Verify:**
```bash
# Check groups
groups [child-username]

# Test sudo (should fail)
sudo -u [child-username] sudo -n true
```

**Fix Immediately:**
```bash
# Remove from admin groups
sudo gpasswd -d [child-username] wheel
sudo gpasswd -d [child-username] sudo
sudo gpasswd -d [child-username] admin

# Verify fix
groups [child-username]  # Should NOT see wheel/sudo/admin
```

#### Issue: Apps Won't Launch

**Symptoms:**
- Educational app icon present but nothing happens
- App crashes immediately
- Error messages

**Solutions:**
```bash
# 1. Check malcontent app restrictions
malcontent-control
# Select child → App Filter → Verify app is allowed

# 2. Try launching from terminal (as child)
sudo -u [child-username] gcompris-qt

# 3. Reinstall app
sudo dnf reinstall gcompris-qt

# 4. Check for missing dependencies
sudo dnf check
```

#### Issue: DNS Filtering Not Working

**Symptoms:**
- Inappropriate sites still accessible
- Content filter not blocking

**Solutions:**
```bash
# 1. Verify DNS settings (in VM)
nmcli dev show | grep DNS

# Should see:
# IP4.DNS[1]: 208.67.222.123
# IP4.DNS[2]: 208.67.220.123

# 2. If not set, configure manually:
# Parallels: VM Config → Hardware → Network → Advanced → DNS
# Enter OpenDNS FamilyShield addresses

# 3. Test filtering:
dig @208.67.222.123 playboy.com  # Should return blocked IP

# 4. Restart VM for changes to take effect
sudo systemctl reboot
```

#### Issue: Forgot Child's Password

**Solution:**
```bash
# Reset password (as parent/sudo user)
sudo passwd [child-username]

# Enter new password twice

# Teaching moment:
# - Why strong passwords matter
# - How to create memorable passwords
# - Never share except with parents
```

#### Issue: VM Running Slow

**Solutions:**
```bash
# 1. Check disk space
df -h /home

# 2. Clear cache (as child)
sudo -u [child-username] rm -rf /home/[child-username]/.cache/*

# 3. Check Parallels resources
# VM Config → Hardware → CPU (4 cores min)
# VM Config → Hardware → Memory (6 GB recommended)

# 4. Close unused apps
# In GNOME: Alt+Tab, close what's not needed

# 5. Reduce GNOME animations (already done by script)
# If not: gsettings set org.gnome.desktop.interface enable-animations false
```

---

## 📈 Growth Path: Scaling with Your Child

### Ages 4-6: Foundation Phase

**Focus**: Supervised exploration, basic skills
**Time Limits**: 1-2 hours/day, fully supervised
**Independence Level**: 0-20%

**Apps to Emphasize:**
- GCompris (simple activities)
- Tux Paint
- Tux Math (easy mode)

**Parent Role:**
- Direct supervision always
- Help navigate interfaces
- Explain concepts
- Celebrate all attempts

### Ages 6-8: Skill Building Phase

**Focus**: Independent exploration, reading/math fundamentals
**Time Limits**: 2-3 hours/day, supervised initially
**Independence Level**: 20-40%

**Apps to Add:**
- Tux Typing (essential!)
- Marble (geography)
- KWord Quiz

**Parent Role:**
- Periodic check-ins (15-20 min)
- Review work together
- Encourage experimentation
- Build confidence

### Ages 8-10: Independence Phase

**Focus**: Self-directed learning, programming introduction
**Time Limits**: 2-4 hours/day, check-ins
**Independence Level**: 40-60%

**Apps to Add:**
- Scratch (programming)
- GIMP/Inkscape
- Stellarium
- Python basics

**Parent Role:**
- Visible presence
- Project guidance
- Interest support
- Technical help when needed

### Ages 10-12: Responsibility Phase

**Focus**: Advanced skills, creative projects, responsibility
**Time Limits**: 3-5 hours/day, monitoring
**Independence Level**: 60-80%

**Apps to Add:**
- Advanced programming
- Professional creative tools
- Research capabilities
- Collaboration tools

**Parent Role:**
- Monthly reviews
- Project mentoring
- Preparing for teen transition
- Gradual reduction of restrictions

### Ages 12+: Transition Plan

**Goal**: Move to standard Fedora account

**Preparation:**
1. Demonstrate responsibility (6+ months)
2. No rule violations
3. Consistent good judgment
4. Earned trust

**Transition Steps:**
```bash
# 1. Create standard user account
sudo useradd -m -G wheel [username]

# 2. Migrate learning materials
sudo cp -r /home/[old-account]/* /home/[new-account]/
sudo chown -R [new-account]: /home/[new-account]

# 3. Gradual independence
# - Remove DNS filtering (trust)
# - Remove time limits (responsibility)
# - Keep monitoring (transparency)

# 4. New rules for teen account
# - Discuss expectations
# - Establish trust boundaries
# - Maintain open communication
```

---

## 💡 Advanced Topics

### Adding Custom Educational Software

**From Fedora Repositories:**
```bash
# Search for educational apps
dnf search education

# Install specific app
sudo dnf install [package-name]

# Make available to child via malcontent-control
malcontent-control
# Select child → App Filter → Add app
```

**From Flatpak:**
```bash
# Install Flatpak (if not present)
sudo dnf install flatpak

# Add Flathub
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Install educational app
flatpak install flathub org.kde.kturtle  # Example: KTurtle programming

# Allow in malcontent-control
```

### Customizing Time Limits

**Different limits for different days:**
```bash
# Use malcontent-control GUI
# Set weekday limits (Mon-Fri): 2 hours
# Set weekend limits (Sat-Sun): 4 hours
```

**Grace period before lockout:**
- Malcontent shows warnings: 15 min, 5 min, 1 min
- Teach child to save work when warned

### Multi-Child Households

**Separate Accounts (Recommended):**
```bash
# Run bootstrap for each child
./scripts/bootstrap/kids-fedora-bootstrap.sh --child-name "Sofia" --child-age 8
./scripts/bootstrap/kids-fedora-bootstrap.sh --child-name "Marco" --child-age 11

# Each gets:
# - Own account
# - Age-appropriate software
# - Individual time limits
# - Separate monitoring
```

**Shared Account (Not Recommended):**
- Difficult to monitor individually
- Can't customize per age
- May cause sibling conflicts

### Handling Special Needs

**Visual Impairments:**
```bash
# Larger text (already set to 1.15x)
gsettings set org.gnome.desktop.interface text-scaling-factor 1.25  # Even larger

# High contrast theme
gsettings set org.gnome.desktop.a11y.interface high-contrast true

# Screen reader
sudo dnf install orca
```

**Hearing Impairments:**
```bash
# Visual notifications
gsettings set org.gnome.desktop.a11y visual-bell true

# Subtitles for videos (ensure videos have captions)
```

**Learning Disabilities:**
- More supervision and guidance
- Break learning into smaller chunks
- Celebrate all progress
- Consider specialized educational software

---

## 📚 Resources

### Official Documentation
- [Guide 3: Fedora VM Creation](parallels-3-fedora-vm-creation.md)
- [Guide 4: Manual Kids Setup](parallels-4-fedora-kids-setup.md)
- [Educational Packages List](../../system/fedora/educational-packages.txt)

### External Resources
- **GCompris**: https://gcompris.net/
- **KDE Education**: https://edu.kde.org/
- **Scratch**: https://scratch.mit.edu/
- **OpenDNS FamilyShield**: https://www.opendns.com/setupguide/#familyshield
- **Common Sense Media**: https://www.commonsensemedia.org/ (app reviews)

### Community Support
- **Fedora Forums**: https://discussion.fedoraproject.org/
- **r/Fedora**: Reddit community
- **Ask Fedora**: https://ask.fedoraproject.org/

### When to Seek Professional Help

**Consider consulting a professional if:**
- Excessive screen time affecting school performance
- Signs of online bullying or harassment
- Exposure to inappropriate content causing distress
- Obsessive behavior with specific apps/games
- Secretive or deceptive behavior online

**Resources:**
- School counselor
- Child psychologist
- Online safety organizations
- Local parent support groups

---

## 🎉 Success Stories

### What Good Use Looks Like

**Example: Sofia, Age 8**
- Uses GCompris 30 min/day for math practice
- Tux Paint for creative expression (30 min)
- Scratch for simple programming (1 hour, 2x/week)
- Total: ~2 hours/day within limits
- Balanced with outdoor play, reading, family time
- Excited to share projects with parents
- **Result**: Improved math scores, creative confidence

**Example: Marco, Age 11**
- Python programming projects (1 hour/day)
- Scratch advanced games (30 min)
- GIMP for school project (as needed)
- Research for homework (supervised, 30 min)
- Total: ~3 hours/day, flexible for projects
- **Result**: Learned problem-solving, created portfolio

### Building Digital Citizenship

**Teach Kids:**
- Computers are tools for learning and creating
- Internet is powerful but requires responsibility
- Privacy matters (theirs and others')
- Kindness online = kindness in real life
- Ask for help when unsure

**Model Behavior:**
- Use your own devices responsibly
- Follow your own screen time rules
- Demonstrate good online citizenship
- Be transparent about your own usage

---

## 📝 Maintenance Log Template

**Keep a simple log to track:**

```
Date: [YYYY-MM-DD]
Child: [Name]
Activity: [What was done]
Time: [Duration]
Notes: [Observations, concerns, celebrations]
Adjustments: [Changes made to settings]

Example:
Date: 2025-10-26
Child: Sofia
Activity: GCompris math games, Tux Paint drawings
Time: 2 hours
Notes: Very engaged with fractions in GCompris. Created beautiful drawing of family.
Adjustments: None needed, she's within limits and enjoying learning.
```

---

## 🏆 Final Thoughts

This environment is a **tool for learning and safety**, not surveillance. The goal is to:

1. **Protect** your child from online dangers
2. **Educate** them about digital citizenship
3. **Empower** them with skills for the future
4. **Build trust** through transparency and communication

Remember:
- Perfect is the enemy of good (some screen time is okay!)
- Balance is key (online + offline activities)
- Trust grows with responsibility
- Technology is a tool, not a replacement for parenting

### Your Role

You're not just monitoring a computer system—you're teaching your child to navigate the digital world safely and responsibly. That's one of the most important skills they'll learn.

**Questions? Issues? Improvements?**

This guide is living documentation. As you use this system, you'll discover what works for YOUR family. Trust your judgment, stay engaged, and enjoy watching your child learn and grow!

---

**Happy Learning! 🎓**

---

*This guide was created as part of the Kids' Fedora Learning Environment project.*
*For technical documentation, see: docs/guides/parallels-4-fedora-kids-setup.md*
*For automated setup: scripts/bootstrap/kids-fedora-bootstrap.sh*

*Last updated: 2025-10-26*
