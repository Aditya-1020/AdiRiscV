ALU_ADD   = 0   # 4'b0000
ALU_SUB   = 1   # 4'b0001
ALU_SLL   = 2   # 4'b0010
ALU_SLT   = 3   # 4'b0011
ALU_SLTU  = 4   # 4'b0100
ALU_XOR   = 5   # 4'b0101
ALU_SRL   = 6   # 4'b0110
ALU_SRA   = 7   # 4'b0111
ALU_OR    = 8   # 4'b1000
ALU_AND   = 9   # 4'b1001

cases = [
    ("00", "0", "000", ALU_ADD),
    ("01", "0", "000", ALU_SUB),

    ("10", "0", "000", ALU_ADD),
    ("10", "1", "000", ALU_SUB),
    ("10", "0", "001", ALU_SLL),
    ("10", "0", "010", ALU_SLT),
    ("10", "0", "011", ALU_SLTU),
    ("10", "0", "100", ALU_XOR),
    ("10", "0", "101", ALU_SRL),
    ("10", "1", "101", ALU_SRA),
    ("10", "0", "110", ALU_OR),
    ("10", "0", "111", ALU_AND),
   
]

with open("tb/test_vectors.mem", "w") as f:
    for aluop, i30, f3, expected in cases:
        word = (int(aluop,2) << 10) | (int(i30) << 9) | (int(f3,2) << 6) | (expected << 2)
        f.write(f"{word:03x}\n")