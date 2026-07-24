module smoke_tb;
  initial begin
    $display("DSim smoke test: hello from SystemVerilog");
    if (5 + 7 == 12)
      $display("PASS: arithmetic check ok");
    else
      $display("FAIL: arithmetic check failed");
    $finish;
  end
endmodule
