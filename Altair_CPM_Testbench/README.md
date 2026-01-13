# Arc's Altair8800 CP/M Testbench
A little repository housing a CP/M testbench I needed to use for one of my courses. <br>
Runs perfectly on Mac, Unix terminal commands listed, other OS executables provided. Adjust commands accordingly, and don't whinge at me if it doesn't work elsewhere. <br>
All the credit for the simulator goes to the wonderful folks that create and maintain [SIMH](https://github.com/simh/simh). <br>

## System Details
### Getting the difference: simulator capabilities vs CP/M capabilities
The **SIMH Altair 8800 simulator** (the `altair8800` executable) is extremely flexible:
- Supports **16 disk drives** (example: DSK0 through DSK15)
- Can hot-swap disk images while running (more on this fascinating bit later)
- Emulates an 8080 CPU with up to 8978KB per disk unit
- Provides a full hardware environment for running "vintage" operating systems (which serves no direct, functional purpose – have fun with it!)

The **CP/M 2.2 operating system** running *inside* the simulator has stricter limitations:
- Supports only **4 logical drives**: **A:, B:, C:, D:**
- A: is **always** the system/boot drive, that is a core feature of CP/M as a system
- Each drive can be mounted/unmounted, but CP/M only sees 4 at a time, this was due to how the software was written (to fit with the hardware it was for)
- Total memory: **59K-63K** usable RAM (not the full capacity of the simulated hardware, but well over what was realistically needed by the system)

Think of it this way: <br>
The **simulator** is like having 16 physical floppy disk drives on your desk. <br>
**CP/M** is like having only 4 drive letters available in your operating system. <br>
You can physically swap disks in/out of the drives, and CP/M always labels them A:, B:, C:, D: <br>
However, as you are not sitting at a desk with an a retro computer, but likely laying in bed with a modern laptop, you don't have floppy disks, nor drives for them. <br>
So to bypass this, the simulator provides a "virtual desk" of sorts, which I will give a basic rundown of below. <br>
This means that, while you can't access 16 drives simultaneously, what you CAN do is hot-swap disk images to access different software without rebooting. <br>

## Available Disk Images
This workspace (currently) contains the following disk images:
| Filename | Contents | Size |
|----------|----------|------|
| `A.dsk` | CP/M 2.2 System Disk (DISK01) | 338KB |
| `supercalc.dsk` | SuperCalc II Spreadsheet (DISK06) | 338KB |
| `zork.dsk` | Zork I Text Adventure Game (DISK08) | 338KB |
| `games.dsk` | Collection of misc. CP/M Games (DISK05) | 338KB |
| `devtools.dsk` | Development Tools: M80, L80, MAC, ASM, ED (DISK13) | 338KB |
| `editor.dsk` | Contains ED, R, W, ASM, and LOAD | 338KB |

The (DISKXX) filenames may not mean anything to you, [but they sure do for a certain someone.](https://codeberg.org/jelkner)

## Starting the Simulator
### Initial boot
From whatever you name this directory (default `Altair_CPM_Testbench`):
```bash
./altair8800mac cpm
```
This will:
1. Load the 8080 CPU emulation, using the "cpm" config
2. Attach `A.dsk` (CP/M system disk) to drive A:
3. Load the disk boot loader at address FF00
4. Boot CP/M 2.2
You should see:
```
Altair 8800 (Z80) simulator Open SIMH V4.1-0 Current

59K CP/M
Version 2.2mits (07/28/80)
Copyright 1980 by Burcon Inc.

A>
```
The `A>` prompt means you're in CP/M, on drive A:. <br>
Congrats. You have successfully downgraded your system from a floating window manager (hyprland users aren't real and can't hurt us) that could launch approximately 16 million (assuming 64GB RAM, and ignoring the fact DDR4/5 is **MILES** faster than the "format" that would have existed back then) Apollo 11 missions, to something that could run... quite a few less. Several orders of magnitude less.

## Hot-Swapping Disk Images
This is the meat of the matter, and what makes this simulator actually useful.
### Introducing: the Control-E interface
While the simulator is running, you can press **Ctrl+E** to pause execution and access the simulator's command interface. This is the equivalent of a management panel for a VM – things you'd physically do to a computer, but can't as there *isn't* a physical computer that exists.
### Step-by-step rundown
1. **Pause the simulator**
   - While CP/M is running (at any prompt like `A>`), press **Ctrl+E**
   - You'll see the `sim>` prompt
2. **Check current disk attachments** (optional)
   ```
   sim> SHOW DSK
   ```
   This shows all 16 disk units and what's currently attached.
3. **Attach a disk image**
   ```
   sim> ATTACH DSK1 supercalc.dsk
   ```
   - `DSK0` = A: drive (system disk - usually leave this alone)
   - `DSK1` = B: drive
   - `DSK2` = C: drive
   - `DSK3` = D: drive
4. **Detach a disk** (if needed)
   ```
   sim> DETACH DSK1
   ```
5. **Resume CP/M**
   ```
   sim> CONT
   ```
   (or just `C` for short) <br>
   Note: Be warned. Get a coffee. Or a meal. Or a wife and kids, because you'll have time for that too, while it's recombobulating itself. <br>
   If, however, you have better things to do in life than go and get a life, hit **Ctrl-C** to interrupt the "realism" process and get to actually use the system.
6. **Access the new drive in CP/M**
   - At the `A>` prompt, type:
   ```
   A> B:
   ```
   - The prompt changes to `B>`, and you're now on drive B.
   - Type `DIR` to see files on the disk.
   ```
   B> DIR
   ```
Did you get all that? Great, because I had Claude Code babysit me for 20 minutes as I tried to process how all of that works, and cannot help you any more than this documentation will. Good luck soldier.

## Common CP/M Commands
These work from any drive prompt (A>, B>, etc.):

| Command | Description | Example |
|---------|-------------|---------|
| `DIR` | List files on current drive | `DIR` |
| `DIR B:` | List files on drive B: | `DIR B:` |
| `A:` | Switch to drive A: | `A:` |
| `TYPE FILE.TXT` | Display text file contents | `TYPE README.TXT` |
| `ERA FILE.TXT` | Erase (delete) a file | `ERA TEMP.TXT` |
| `REN NEW.TXT=OLD.TXT` | Rename a file | `REN LETTER2.TXT=LETTER.TXT` |
| `PIP` | File copy utility | `PIP B:=A:FILE.TXT` |
| `STAT` | Show disk statistics | `STAT` |

**Warm boot**: Press **Ctrl+C** at any CP/M prompt to reload the operating system (useful after disk swaps).

## Quick Start Example Session
Here's a complete example of starting the simulator and running Zork:

```bash
$ ./altair8800mac cpm
Altair 8800 (Z80) simulator Open SIMH V4.1-0 Current

59K CP/M
Version 2.2mits (07/28/80)

A> [Press Ctrl+E]

sim> ATTACH DSK1 zork.dsk
sim> CONT

A> B:
B> DIR
B> ZORK1

[Zork opens - explore the Great Underground Empire!]

[Type QUIT to exit Zork]

B> A:
A> [Press Ctrl+E]

sim> QUIT

$
```

## Checking Drives Without Booting
This is vital for if your teacher/professor/instructor/idle curiosity leads you to downloading a peculiar folder full of `.DSK` files and you have not the slightest clue what they contain. Not pointing any fingers. <br>
To see what's on each disk without booting, you can use the `strings` command on your host system:

```bash
strings supercalc.dsk | grep "\.COM$"
```

This will show you the executable files on the disk image.

## Misc. Notes
- The simulator runs at historically accurate speeds by default (that is, abysmally slow! I could not stomach sitting through the loading times even once past the first time!). 
   - You can adjust this by inserting `set throttle 50%` (for it to crank with 50% of your CPU power) or `set nothrottle` (not recommended) into the `cpm` file, onto the second line.
- All disk images are 330KB (standard 8" single-density floppy format).
- CP/M is case-insensitive (commands can be typed in upper or lower case, which is a big win over modern Windows, for one).
- The system disk (A.dsk) should remain mounted on DSK0 at all times (unless you don't want to have a bootable system, of course).

## Application Usage Guide
Note! This below part is written entirely by Claude Code. Its reliability is prone to being null. <br>
The extent of terminal-based software I use are `btop` and `nano`, and while I have gone through and tried most of these, I will highlight that the ability to use SuperCalc II was a skill that would singlehandedly get you employed. <br>
I am not seeking employment in that long-gone field at this time, and as such, will not be learning every tiny detail of how to use these.

### 1. SuperCalc II (Spreadsheet)

**What it is**: A powerful spreadsheet program, similar to VisiCalc or early Excel.

**How to use**:

1. **Mount the disk**:
   ```
   [Press Ctrl+E]
   sim> ATTACH DSK1 supercalc.dsk
   sim> CONT
   ```

2. **Switch to drive B: and launch**:
   ```
   A> B:
   B> DIR
   ```
   Look for `SC.COM` or `SUPERCALC.COM`

3. **Run SuperCalc**:
   ```
   B> SC
   ```

4. **Basic commands** (inside SuperCalc):
   - Arrow keys or `/G` command to navigate cells
   - Type values directly into cells
   - `/Q` to quit
   - Consult the disk for README or HELP files if available

5. **Exit**:
   - Follow on-screen prompts or type `/Q`
   - You'll return to the `B>` prompt

---

### 2. Zork I (Text Adventure Game)

**What it is**: A classic interactive fiction game. You explore the Great Underground Empire, solve puzzles, and collect treasures.

**How to use**:

1. **Mount the disk**:
   ```
   [Press Ctrl+E]
   sim> ATTACH DSK1 zork.dsk
   sim> CONT
   ```

2. **Switch to drive B: and launch**:
   ```
   A> B:
   B> DIR
   ```
   Look for `ZORK1.COM` or similar

3. **Run Zork**:
   ```
   B> ZORK1
   ```

4. **Playing the game**:
   - Read the text descriptions carefully
   - Type commands like:
     - `GO NORTH` or just `N` (navigate)
     - `TAKE LAMP` (pick up items)
     - `OPEN MAILBOX` (interact with objects)
     - `INVENTORY` or `I` (check what you're carrying)
     - `LOOK` or `L` (look around)
     - `EXAMINE [object]` (inspect closely)
   - Type `HELP` for hints
   - Type `QUIT` to exit

5. **Saving your game**:
   - Type `SAVE` and provide a filename
   - The save file will be on drive B:

6. **Exit**:
   - Type `QUIT`

---

### 3. Games Collection

**What it is**: A collection of various CP/M games (specific titles vary).

**How to use**:

1. **Mount the disk**:
   ```
   [Press Ctrl+E]
   sim> ATTACH DSK1 games.dsk
   sim> CONT
   ```

2. **Browse available games**:
   ```
   A> B:
   B> DIR
   ```
   Look for `.COM` files - these are executable games

3. **Common games you might find**:
   - `ADVENTURE.COM` - Text adventure
   - `CHESS.COM` - Chess game
   - `OTHELLO.COM` - Reversi/Othello
   - `TREK.COM` - Star Trek game
   - And others

4. **Run a game**:
   ```
   B> [GAMENAME]
   ```
   (e.g., `B> CHESS`)

5. **Exit**:
   - Each game has different exit commands
   - Try `Q`, `QUIT`, `EXIT`, or Ctrl+C

---

### 4. Development Tools

**What it is**: Assemblers, linkers, and editors for software development on CP/M.

**Tools included**:
- **M80** - Microsoft 8080/Z80 Macro Assembler
- **L80** - Microsoft Linker
- **MAC** - CP/M Macro Assembler
- **ASM** - CP/M Assembler
- **ED** - CP/M Text Editor
- **MBASIC** - Microsoft BASIC Interpreter

**How to use**:

1. **Mount the disk**:
   ```
   [Press Ctrl+E]
   sim> ATTACH DSK1 devtools.dsk
   sim> CONT
   ```

2. **Switch to drive B:**:
   ```
   A> B:
   B> DIR
   ```

3. **Run tools**:
   - **MBASIC** (Microsoft BASIC):
     ```
     B> MBASIC
     ```
     - Type BASIC programs interactively
     - `LIST` to see your program
     - `RUN` to execute
     - `SAVE "PROGRAM.BAS"` to save
     - `SYSTEM` to exit

   - **ED** (Line Editor):
     ```
     B> ED MYFILE.TXT
     ```
     - `I` to insert text
     - `L` to list lines
     - `E` to exit and save
     - (ED is challenging - consider using WordStar for text editing)

   - **ASM** (Assembler):
     ```
     B> ASM MYPROGRAM.ASM
     ```
     Creates `MYPROGRAM.HEX`

4. **Exit**:
   - Each tool has its own exit command
   - MBASIC: `SYSTEM`
   - ED: `E` (exit and save) or `Q` (quit without saving)

## Tips and Troubleshooting
Also written by Claude Code! I personally had no issues, so best of luck!
### Swapping Disks Mid-Session

**Example workflow** - switching from SuperCalc to Zork:

1. Exit SuperCalc (`/Q`)
2. You're back at `B>` prompt
3. Press **Ctrl+E**
4. At `sim>` prompt:
   ```
   sim> DETACH DSK1
   sim> ATTACH DSK1 zork.dsk
   sim> CONT
   ```
5. Back at `B>`, type `DIR` to verify new disk
6. If DIR shows old files, press **Ctrl+C** to warm boot
7. Type `B:` to reinitialize the drive
8. Run Zork (`ZORK1`)

### Drive Won't Recognize New Disk

If you swap a disk but CP/M still shows old files:
- Press **Ctrl+C** (warm boot)
- Type the drive letter again (e.g., `B:`)
- Type `DIR` to verify

### Can't Find a Program

- Check you're on the right drive (look at the prompt: `A>` vs `B>`)
- Type `DIR` to list files
- CP/M filenames are 8.3 format (8 chars + 3 char extension)
- Executables end in `.COM`

### Exiting the Simulator Completely

1. From any CP/M prompt, press **Ctrl+E**
2. At `sim>` prompt, type:
   ```
   sim> QUIT
   ```
   or just
   ```
   sim> Q
   ```

### Read-Only Disk Attachments

To prevent accidental modification of a disk image:
```
sim> ATTACH -R DSK1 wordstar.dsk
```
The `-R` flag attaches the disk as read-only.

## End of README.md
Congrats. You scrolled through a whole lot of CS student yapping and Claude Code slopumentation. Hope you're proud of yourself.

## Additional Resources
I lied, here's more random stuff you may find useful.
- **SIMH Documentation**: https://simh.trailing-edge.com/
- **Zork**: https://infodoc.plover.net/manuals/zork1.pdf