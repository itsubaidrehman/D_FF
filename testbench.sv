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


class generator;
  transaction tr;
  mailbox #(transaction) mbx;
  int count;
  
  event next;
  event done;
  
  function new(mailbox #(transaction) mbx);
    this.mbx = mbx;
    tr = new();
  endfunction
  
  task run();
    repeat (count) begin
      assert (tr.randomize) else $error("Randomization Failed");
      mbx.put(tr.copy);
      tr.display("GEN");
      @(next);
    end
    ->done;
  endtask
endclass
