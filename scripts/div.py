# Radix-2 - Interative Non Restoring Division

def non_restoring_div(dividend_bin, divisor_bin):
    # Initialize variables
    Q = int(dividend_bin, 2)
    M = int(divisor_bin, 2)
    A = 0
    n = len(dividend_bin) # Number of bits

    for _ in range(n):
        # 1. Shift A and Q left [ A = (A << 1) | MSB(Q) ]
        A = (A << 1) | ((Q >> (n - 1)) & 1)
        Q = (Q << 1) & ((1 << n) - 1) # Keep Q to n bits

        # 2. Add or Subtract M based on sign of A
        if A >= 0: 
            A -= M
        else:
            A += M
            
        # 3. Set Q's least significant bit
        if A >= 0: 
            Q |= 1
        # else: Q |= 0 (implicitly done by shift)

    # 4. Final Restoration if remainder is negative
    if A < 0: 
        A += M

    # Return results as binary strings
    return bin(Q)[2:], bin(A)[2:]

# --- Example Usage ---
if __name__ == "__main__":
    # Inputs: Dividend "1011" (11), Divisor "0011" (3)
    quotient, remainder = non_restoring_div("1011", "0011")
    
    print(f"Quotient:  {quotient}")
    print(f"Remainder: {remainder}")
