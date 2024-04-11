class transaction;
  rand bit din;
  bit dout;
  
  function void display(input string tag);
    $display(" [%0s] -> din : %0b, dout : %0b", tag, din, dout);
  endfunction
  
  
  function transaction copy();
    copy = new();
    copy.din = this.din;
    copy.dout = this.dout;
  endfunction
endclass