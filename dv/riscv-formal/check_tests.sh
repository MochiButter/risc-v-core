result_all=0
for dir in riscv-formal/cores/core/checks/*/; do
  (test -f $dir/PASS)
  result=$?
  if [ $result == 0 ]; then
    printf "$dir \033[0;32mpassed\033[0m\n"
  else
    printf "$dir \033[0;31mfailed\033[0m\n"
  fi
  result_all=$((result_all + result))

done
[ $result_all == 0 ] && printf "\033[0;32mAll tests passed\033[0m\n" || printf "\033[0;31mTest failed\033[0m\n"
exit $result_all
