module reactionTimeGame(
input logic clk,
input logic [9:0] SW, //Vector for switches.
input logic viewBestTime, reset,
output logic [9:0] LED, //Vector for LEDs
output logic [7:0] displ0,
output logic [7:0] displ1,
output logic [7:0] displ2,
output logic [7:0] displ3);
  
int t; //Score Timer.

logic [3:0] tens,ones,tenths,hundredths;
logic [22:0] counter10Hz;//Counter for 0.1s timer.
logic [18:0] counter100Hz; //Counter for 0.01s timer.
logic [23:0] counter2Hz; //Counter for 2Hz clock.
logic [27:0] counter5s; //Counter for 5s timer.
parameter divisor10Hz = 23'd5000000;//0.1s is reached. 50Mhz*0.1s=5M
  
logic initializeRound, roundFinalized, t5s, clk2Hz; //Booleans and clock.
logic [3:0] currentLED, SWCount, i; //i is a counter for a loop.
int fastestTime = 9999;
int currentTime = 0;
wire feedback; //For random number generator/LFSR
  
//Start with initializeRound as 1 to trigger round setup after 5s passes.
initial begin
initializeRound = 1;
t = 0;
end
  
always @(posedge clk) begin
//Increment counters for timing.
counter10Hz++;
counter2Hz++;
counter100Hz++;
counter5s++;
  
//Initialization sequence for the beginning of each round.
if(initializeRound && t5s && !SW[currentLED])
begin
t=0; // reset displaytimer
//Generate a random number between 0 and 10 and store it in
currentLED.(LFSR Linear feedback shift register)
feedback = ~(currentLED[3] ^ currentLED[2]);
currentLED = {currentLED[2:0],feedback}%10;
LED[currentLED] = 1; //Turn on randomly chosen LED.
counter10Hz = 0; //Reset the timer for turning off the LED.
counter100Hz = 0; //Reset the score timer.
initializeRound = 0; //Signal that the initialization has been
completed.
roundFinalized = 0; /* Signal that the code for the correct switch
getting
* flipped was not run for the current round.
* Used to make code run once when the correct switch
* is flipped.*/
end
  
/*Turn off LEDs after 0.1s to complete any blink
* and stop the correct answer blinking after the correct switch is turned
off.*/
if (counter10Hz >= divisor10Hz)
begin
LED = 0;
end
  
//Clock for blinking the LEDs at the correct answer.
if (counter2Hz >= (divisor10Hz*10/4))
begin
clk2Hz = ~clk2Hz;
counter2Hz = 0;
end
  
//Determine whether 0.01s has passed.
if (counter100Hz >= (divisor10Hz/10))
begin
counter100Hz = 0; //Reset counter to continue timing.
if(t5s) t=t+1; //Increment score timer by 0.01s while no delay is in
progress.
// if t outouts 100, that is 100 cs, which is 1 second -> 1.00
//Separate result into its digits.
end
  
//Determine whether 5s has passed.
if (counter5s >= (divisor10Hz*50))
begin
counter5s = 0; //Reset counter to continue timing.
t5s = 1; //Signal that 5s has passed.
end
  
//Ensure that only 1 switch is pressed.
for(i=0; i<$size(SW); i++)
begin
if(SW[i])SWCount++;
end
  
//If the user flips the correct switch and only the correct switch.
if(SW[currentLED] && (SWCount==1))
begin
//Anything here only executes once after the correct switch is
flipped.
if(!roundFinalized)
begin
currentTime = t;
if (t<fastestTime) fastestTime = t;
end
  
t5s = 0; //Reset 5s timer.
//Need this here to make sure the round doesn't reset
immediately.
counter5s = 0; //Reset the counter for the 5s timer.
counter10Hz = 0; //Reset the 10Hz counter so it doesn't interfere with
the blinking.
//Blink all the LEDs while the correct switch is still flipped on.
LED = {clk2Hz,clk2Hz,clk2Hz,clk2Hz,clk2Hz,
clk2Hz,clk2Hz,clk2Hz,clk2Hz,clk2Hz};
initializeRound = 1; //Signal that the next round needs to be
initialized.
roundFinalized = 1; //Signal that all the LEDs need to be blinked due
to correct answer.
end
  
//If any of the switches are still pressed after the correct one is, keep
delaying.
//This allows for system/game pausing in between rounds when any of the
switches are flipped.
if((SWCount>0) && initializeRound)
begin
t5s = 0;//Reset 5s timer.
counter5s = 0; //Reset the counter for the 5s timer.
//Score timer (t) shouldn't work due to t5s/delay
in progress.
if(!viewBestTime)
begin
t = fastestTime;
end
  
else
begin
t = currentTime;
end
  
if(!reset)
begin
fastestTime = 9999;
end
end
  
//Reset switch count.
SWCount = 0;
end
  
//Displaying timer on 7-segment display.
always @(t)
begin
tens= t%10000/1000;
ones = (t%1000)/100;
tenths = (t%100)/10;
hundredths = (t%100)%10;
  
if(tens > 0)
begin
  case(tens)
    4'd0: displ3=8'b11000000;
    4'd1: displ3=8'b11111001;
    4'd2: displ3=8'b10100100;
    4'd3: displ3=8'b10110000;
    4'd4: displ3=8'b10011001;
    4'd5: displ3=8'b10010010;
    4'd6: displ3=8'b10000010;
    4'd7: displ3=8'b11111000;
    4'd8: displ3=8'b10000000;
    4'd9: displ3=8'b10010000;
  default: displ3=8'b11000000;
endcase
end

if(ones > 0)
begin
  case(ones)
    4'd0: displ2=8'b01000000;
    4'd1: displ2=8'b01111001;
    4'd2: displ2=8'b00100100;
    4'd3: displ2=8'b00110000;
    4'd4: displ2=8'b00011001;
    4'd5: displ2=8'b00010010;
    4'd6: displ2=8'b00000010;
    4'd7: displ2=8'b01111000;
    4'd8: displ2=8'b00000000;
    4'd9: displ2=8'b00010000;
  default: displ2=8'b01000000;
endcase
end
  
if((tenths > 0) || (ones > 0))
begin
  case(tenths)
    4'd0: displ1=8'b11000000;
    4'd1: displ1=8'b11111001;
    4'd2: displ1=8'b10100100;
    4'd3: displ1=8'b10110000;
    4'd4: displ1=8'b10011001;
    4'd5: displ1=8'b10010010;
    4'd6: displ1=8'b10000010;
    4'd7: displ1=8'b11111000;
    4'd8: displ1=8'b10000000;
    4'd9: displ1=8'b10010000;
  default: displ1=8'b11000000;
endcase
end
  
if(hundredths >= 0)
begin
  case(hundredths)
    4'd0: displ0=8'b11000000;
    4'd1: displ0=8'b11111001;
    4'd2: displ0=8'b10100100;
    4'd3: displ0=8'b10110000;
    4'd4: displ0=8'b10011001;
    4'd5: displ0=8'b10010010;
    4'd6: displ0=8'b10000010;
    4'd7: displ0=8'b11111000;
    4'd8: displ0=8'b10000000;
    4'd9: displ0=8'b10010000;
  default: displ0=8'b11000000;
endcase
end
end
endmodule
