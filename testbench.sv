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

class driver;
  transaction tr;
  mailbox #(transaction) mbx;
  virtual dff_if vif;
  
  function new(mailbox #(transaction) mbx);
    this.mbx = mbx;
  endfunction
  
  task reset();
    vif.rst <= 1'b1;
    repeat (2) @(posedge vif.clk);
    vif.rst <= 1'b0;
    repeat (2) @(posedge vif.clk);
    $display("Reset Done");
  endtask
  
  task run();
    forever begin
      //@(posedge vif.clk);
      mbx.get(tr);
      vif.din <= tr.din;
      tr.display("DRV");
      @(posedge vif.clk);
    end
  endtask
endclass

class monitor;
  transaction tr;
  mailbox #(transaction) mbx;
  virtual dff_if vif;
  
  function new(mailbox #(transaction) mbx);
    this.mbx = mbx;
    
  endfunction
  
  task run();
    tr = new();
    forever begin
      @(posedge vif.clk);
      @(posedge vif.clk);
      tr.din <= vif.din;
      tr.dout <= vif.dout;
      mbx.put(tr);
      tr.display("Mon");
    end
  endtask
endclass

class scoreboard;
  transaction tr;
  mailbox #(transaction) mbx;
  //virtual dff_if vif;
  
  event sconext;
  
  function new(mailbox #(transaction) mbx);
    this.mbx = mbx;
  endfunction
  
  task run();
    forever begin
      mbx.get(tr);
      tr.display("SCO");
      if (tr.din == tr.dout)
        $display("Data Matched");
      else
        $display("Data Mismatched");
      ->sconext;
    end
  endtask
endclass

class environment;
  
  generator gen;
  driver drv;
  monitor mon;
  scoreboard sco;
  
  event nextgs;
  
  mailbox #(transaction) mbxgd;
  mailbox #(transaction) mbxms;
  
  virtual dff_if vif;
  
  function new(virtual dff_if vif);
    mbxgd = new();
    gen = new(mbxgd);
    drv = new(mbxgd);
    
    mbxms = new();
    mon = new(mbxms);
    sco = new(mbxms);
    
    this.vif = vif;
    mon.vif = this.vif;
    drv.vif = this.vif;
    
    gen.next = nextgs;
    sco.sconext = nextgs;
    
  endfunction
  
  task pre_test();
    drv.reset();
  endtask
  
  task test();
    fork
      gen.run();
      drv.run();
      mon.run();
      sco.run();
    join_any
  endtask
  
  task post_test();
    wait(gen.done.triggered);
    $finish();
  endtask
  
  task run();
    pre_test();
    test();
    post_test();
  endtask
endclass