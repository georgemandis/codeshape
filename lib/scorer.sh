# score_record <ccn> <len> <args> <nesting> <dup_ratio>  → score in [1.0,10.0]
score_record() {
  awk -v ccn="$1" -v len="$2" -v args="$3" -v nest="$4" -v dup="$5" \
      -v tccn="$T_CCN" -v tlen="$T_LEN" -v targs="$T_ARGS" -v tnest="$T_NEST" \
      -v wccn="$W_CCN" -v wlen="$W_LEN" -v wargs="$W_ARGS" -v wnest="$W_NEST" -v wdup="$W_DUP" '
    function over(x, t) { return (x > t) ? (x - t) : 0 }
    BEGIN {
      s = 10 - wccn*over(ccn,tccn) - wlen*over(len,tlen) \
             - wargs*over(args,targs) - wnest*over(nest,tnest) - wdup*dup
      if (s < 1) s = 1; if (s > 10) s = 10
      printf "%.1f", s
    }'
}
