#!/usr/bin/env python3
import argparse, random

def gen_matrix(rows, cols, lo=-4, hi=4):
    return [[random.randint(lo, hi) for _ in range(cols)] for _ in range(rows)]

def write_hex(path, mat):
    with open(path, 'w') as f:
        for row in mat:
            for v in row:
                vv = (v & 0xFFFF)
                f.write(f"{vv:04x}\n")

if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument('--m', type=int, default=4)
    ap.add_argument('--n', type=int, default=4)
    ap.add_argument('--k', type=int, default=4)
    ap.add_argument('--out_a', type=str, default='A.hex')
    ap.add_argument('--out_b', type=str, default='B.hex')
    args = ap.parse_args()

    A = gen_matrix(args.m, args.k)
    B = gen_matrix(args.k, args.n)
    write_hex(args.out_a, A)
    write_hex(args.out_b, B)
    print(f"Wrote {args.out_a} and {args.out_b}") 