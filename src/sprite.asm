; Sprites: 16x16 pixels, 16 rows of 2 bytes, top row first, leftmost pixel
; in bit 7 of the first byte. A set bit is ink, a clear bit paper.

    MODULE Sprite

; Wall: brickwork, in Color.WALL_ATTR: white mortar (ink) between dark red
; bricks (paper). Each course is a mortar line and 3 lines of bricks 8
; pixels wide, offset by half a brick from the course above, so walls side
; by side or one above the other continue the pattern.
wall:
    DG ################
    DG #.......#.......
    DG #.......#.......
    DG #.......#.......
    DG ################
    DG ....#.......#...
    DG ....#.......#...
    DG ....#.......#...
    DG ################
    DG #.......#.......
    DG #.......#.......
    DG #.......#.......
    DG ################
    DG ....#.......#...
    DG ....#.......#...
    DG ....#.......#...
    ASSERT $ - wall == 32

; Target: concentric squares, inset 3 pixels from the edges, so the
; bulldozer's blade (which reaches the edge of its square) never touches it.
target:
    DG ................
    DG ................
    DG ................
    DG ...##########...
    DG ...#........#...
    DG ...#.######.#...
    DG ...#.#....#.#...
    DG ...#.#.##.#.#...
    DG ...#.#.##.#.#...
    DG ...#.#....#.#...
    DG ...#.######.#...
    DG ...#........#...
    DG ...##########...
    DG ................
    DG ................
    DG ................

; Crate: fills its square, with a frame and an X brace drawn in paper. The
; paper margin at the edge shows a seam between crates side by side.
crate:
    DG ................
    DG .##############.
    DG .#............#.
    DG .#..########..#.
    DG .#.#.######.#.#.
    DG .#.##.####.##.#.
    DG .#.###.##.###.#.
    DG .#.####..####.#.
    DG .#.####..####.#.
    DG .#.###.##.###.#.
    DG .#.##.####.##.#.
    DG .#.#.######.#.#.
    DG .#..########..#.
    DG .#............#.
    DG .##############.
    DG ................

; Bulldozer, seen from above, facing each direction in the order of the
; Level directions (UP, RIGHT, DOWN, LEFT): tracks on both sides, the cab in
; the middle, and the blade at the front, reaching the edge of its square.
bulldozer:
bulldozer_up:
    DG .##############.
    DG .##############.
    DG ....#......#....
    DG ###.#......#.###
    DG #.#.########.#.#
    DG ###.########.###
    DG #.#.##....##.#.#
    DG ###.##....##.###
    DG #.#.##....##.#.#
    DG ###.########.###
    DG #.#.########.#.#
    DG ###.##.##.##.###
    DG #.#.########.#.#
    DG ###.##.##.##.###
    DG #.#.########.#.#
    DG ###..........###
bulldozer_right:
    DG #############...
    DG #.#.#.#.#.#.#.##
    DG #############.##
    DG ..............##
    DG .###############
    DG .###########..##
    DG .#.#.##...##..##
    DG .######...##..##
    DG .######...##..##
    DG .#.#.##...##..##
    DG .###########..##
    DG .###############
    DG ..............##
    DG #############.##
    DG #.#.#.#.#.#.#.##
    DG #############...
bulldozer_down:
    DG ###..........###
    DG #.#.########.#.#
    DG ###.##.##.##.###
    DG #.#.########.#.#
    DG ###.##.##.##.###
    DG #.#.########.#.#
    DG ###.########.###
    DG #.#.##....##.#.#
    DG ###.##....##.###
    DG #.#.##....##.#.#
    DG ###.########.###
    DG #.#.########.#.#
    DG ###.#......#.###
    DG ....#......#....
    DG .##############.
    DG .##############.
bulldozer_left:
    DG ...#############
    DG ##.#.#.#.#.#.#.#
    DG ##.#############
    DG ##..............
    DG ###############.
    DG ##..###########.
    DG ##..##...##.#.#.
    DG ##..##...######.
    DG ##..##...######.
    DG ##..##...##.#.#.
    DG ##..###########.
    DG ###############.
    DG ##..............
    DG ##.#############
    DG ##.#.#.#.#.#.#.#
    DG ...#############
    ASSERT bulldozer_right - bulldozer == @Level.RIGHT * 32
    ASSERT bulldozer_down - bulldozer == @Level.DOWN * 32
    ASSERT bulldozer_left - bulldozer == @Level.LEFT * 32

    ENDMODULE
