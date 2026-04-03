Architecture:
The engine consists of NUM_OLANES parallel compute lanes, instantiated in mvm.sv, each responsible for producing one element of the output vector. 
Each lane contains:
Dot Product Unit (dot8): computes an 8-element signed integer dot product.
Accumulator (accum): accumulates partial dot products across multiple memory words to produce a final output element.
Matrix Memory (mem): stores the lane's partition of the input matrix.

A shared Vector Memory feeds all lanes simultaneously, and a Control FSM (ctrl) sequences read addresses, valid signals, and accumulator control flags with pipeline delay compensation.
