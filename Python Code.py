import numpy as np


def building_block(top, bot, angle):
    """
    Implements the logic from Fig. 2 / uploaded image.
    - top: Top m-component vector
    - bot: Bottom m-component vector
    - angle: The skew angle 'a' for 2cos(a)
    """
    # Jm: Reverses the bottom vector
    reversed_bot = bot[::-1]

    # First Summation: Top branch - Reversed Bottom branch
    # (Note: Based on the '-' sign at the sigma node in the image)
    inter_top = top - reversed_bot

    # Multiplier Path: 2 * cos(angle) * original bottom branch
    inter_bot = (2 * np.cos(angle)) * bot

    # Final Crossover Butterfly (Right side of Fig. 2)
    # Top output = inter_top + inter_bot
    # Bottom output = inter_top - inter_bot
    out_top = inter_top + inter_bot
    out_bot = inter_top - inter_bot

    return out_top, out_bot


def fast_dct_16_engine(x):
    x = np.array(x, dtype=float)

    # --- LAYER 1: Initial 16-point Split (DCT-2_16 -> DCT-2_8 + DCT-4_8) ---
    # Based on B_2n matrix [cite: 117, 129]
    l1_top = x[:8] + x[15:7:-1]
    l1_bot = x[:8] - x[15:7:-1]

    # --- LAYER 2: 8-point Decimation ---
    # DCT-2_8 -> DCT-2_4 + DCT-4_4
    l2_dct2_4 = l1_top[:4] + l1_top[7:3:-1]
    l2_dct4_4 = l1_top[:4] - l1_top[7:3:-1]

    # DCT-4_8 enters BB with r=1/2 (angle pi/4) [cite: 141, 158]
    l2_dct4_8_top, l2_dct4_8_bot = building_block(l1_bot[:4], l1_bot[4:], np.pi / 4)

    # --- LAYER 3: 4-point Decimation ---
    # DCT-2_4 -> DCT-2_2 + DCT-4_2
    l3_dct2_2 = l2_dct2_4[:2] + l2_dct2_4[3:1:-1]
    l3_dct4_2 = l2_dct2_4[:2] - l2_dct2_4[3:1:-1]

    # DCT-4_4 enters BB (angle pi/4)
    l3_dct4_4_top, l3_dct4_4_bot = building_block(l2_dct4_4[:2], l2_dct4_4[2:], np.pi / 4)

    # DCT-4_8 paths enter BBs (angles pi/8 and 3pi/8) [cite: 205, 208]
    l3_dct4_8_t1, l3_dct4_8_t2 = building_block(l2_dct4_8_top[:2], l2_dct4_8_top[2:], np.pi / 8)
    l3_dct4_8_b1, l3_dct4_8_b2 = building_block(l2_dct4_8_bot[:2], l2_dct4_8_bot[2:], 3 * np.pi / 8)

    # --- LAYER 4: Final 2-point Core Outputs ---
    # X0, X8 (from DCT-2_2)
    x0, x8 = l3_dct2_2[0] + l3_dct2_2[1], l3_dct2_2[0] - l3_dct2_2[1]

    # X4, X12 (from DCT-4_2 BB pi/4) [cite: 192, 194]
    x4, x12 = building_block(np.array([l3_dct4_2[0]]), np.array([l3_dct4_2[1]]), np.pi / 4)

    # X2, X6, X10, X14 (from DCT-4_4 path) [cite: 198-206]
    x2, x6 = building_block(np.array([l3_dct4_4_top[0]]), np.array([l3_dct4_4_top[1]]), np.pi / 8)
    x10, x14 = building_block(np.array([l3_dct4_4_bot[0]]), np.array([l3_dct4_4_bot[1]]), 3 * np.pi / 8)

    # X1, X3, X5, X7, X9, X11, X13, X15 (from DCT-4_8 path) [cite: 210-229]
    x1, x3 = building_block(np.array([l3_dct4_8_t1[0]]), np.array([l3_dct4_8_t1[1]]), np.pi / 16)
    x5, x7 = building_block(np.array([l3_dct4_8_t2[0]]), np.array([l3_dct4_8_t2[1]]), 7 * np.pi / 16)
    x9, x11 = building_block(np.array([l3_dct4_8_b1[0]]), np.array([l3_dct4_8_b1[1]]), 3 * np.pi / 16)
    x13, x15 = building_block(np.array([l3_dct4_8_b2[0]]), np.array([l3_dct4_8_b2[1]]), 5 * np.pi / 16)

    # Combine into sorted list [X0, X1, ... X15]
    final_output = [x0, x1[0], x2[0], x3[0], x4[0], x5[0], x6[0], x7[0],
                    x8, x9[0], x10[0], x11[0], x12[0], x13[0], x14[0], x15[0]]

    return np.round(final_output, 4)


# Test with your specific input
input_signal = np.array([1, 3, 5, 7, 9, 17, 19, 21, 22, 18, 18, 16, 8, 6, 4, 2])
output = fast_dct_16_engine(input_signal)
print(f"Engine Core Output:\n{list(output)}")
