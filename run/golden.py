import numpy as np
import argparse

def main(R, K, C, DIR):
    # Generate random matrices
    k = np.random.randint(-128, 127, size=(K, C), dtype=np.int32)
    x = np.random.randint(-128, 127, size=(K, R), dtype=np.int32)
    a = np.random.randint(-2147483648, 2147483647, size=(C, R), dtype=np.int32)
    
    # Concatenate matrices
    with open(f"{DIR}/kxa.bin", "wb") as f:
        f.write(k.astype(np.int8 ).tobytes())
        f.write(x.astype(np.int8 ).tobytes())
        f.write(a.astype(np.int32).tobytes())
    
    y = k.T @ x + a # y(C,R) = k.T(C,K) @ x(K,R) + a(C,R)
    
    # Write y to binary file
    with open(f"{DIR}/y_exp.bin", "wb") as f:
        f.write(y.astype(np.int32).tobytes())

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate matrices and perform matrix operations.")
    parser.add_argument("--R", type=int, required=True, help="Number of rows in x and a")
    parser.add_argument("--K", type=int, required=True, help="Number of rows in k and columns in x")
    parser.add_argument("--C", type=int, required=True, help="Number of columns in k and a")
    parser.add_argument("--DIR", type=str, required=True, help="Full directory path to save matrices")
    args = parser.parse_args()
    
    main(args.R, args.K, args.C, args.DIR)