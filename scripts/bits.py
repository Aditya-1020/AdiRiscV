def mask(width):
    return (1<< width) - 1

def to_unsigned(val, width):
    return val & mask(width)

def to_signed(val, width):
    sign = 1 << (width - 1)
    val &= mask(width)
    return (val ^ sign) - sign

def sv_hex(val, width):
    digits = (width + 3) // 4
    return f"{width}'h{to_unsigned(val, width):0{digits}X}"

def sv_bin(val, width):
    return f"{width}'b{to_unsigned(val,width):0{width}b}"

def explain(val, width):
    u = to_unsigned(val, width)
    s = to_signed(val, width)
    
    print(f"f\n value ({width} bits)")
    print("-" * 40)
    print(f"input value = {val}")
    print(f"unsigned value = {u}")
    print(f"signed value = {s}")
    print(f"hex value = {sv_hex(val, width)}")
    print(f"binary value = {sv_bin(val, width)}")

if __name__ == "__main__":
    import sys
    
    if len(sys.argv) != 3:
        print("usage: <value> <width>")
        print("ex: -4 12")
        sys.exit(1)
        
    value = int(sys.argv[1], 0)
    width = int(sys.argv[2])
    
    explain(value, width)
    