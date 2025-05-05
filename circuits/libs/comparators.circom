// comparators.circom
template Num2Bits(n) {
    signal input in;
    signal output out[n];
    var lc = 0;
    for (var i = 0; i < n; i++) {
        out[i] <-- (in >> i) & 1;
        out[i] * (out[i] - 1) === 0;
        lc += out[i] * (1 << i);
    }
    lc === in;
}

template LessThan(n) {
    signal input in[2];
    signal output out;
    component lt = Num2Bits(n+1);
    lt.in <== in[0] + (1<<n) - in[1];
    out <== 1 - lt.out[n];
}