
# Design Decisions for this application

## APRSPacket

- Immutable, created with an APRSPacketBuilder to make parameter entry easier.
- For smaller memory footprint of packet, info is stored as arrays of Uint8
- Rehydratable into a contiguous string of bits, unstuffed

## APRSListener

- Gets +/- samples from a Sampler
    - Queue of Bools
    
- Decodes NRZI to simple 1s and 0s
- Finds flag locations
    - Start out with empty packet
    - Starts in search state, looking to see if we can find 1111110 (first 0 might have been curtailed)
    - Once a flag is found, we go into packet search mode and dequeue the flag bits
        - If we find another flag, just dequeue it again
        - Keep putting bools on the output packet as long as we don't see 6 ones in a row (vectorize this?)
        - Once we see 6 ones in a row, then a zero, we know it's a flag and can cut off the end of the packet
        - Put packet into output queue if it is greater in length than 152 bytes, or shorter than 3168 bytes.
        - go back into search mode 
- Dumps de-stuffed bytes from between successive flags (if they are >= 19 bytes between flags) into the APRSPacketBuilder, after unstuffing, which will separate the packet fields and compute the CRC. If the packet doesn't build, then nil will be returned. 


## Concurrency
- Start out with non-concurrent chain of signal processing. If it isn't fast enough, try vectorization and cache blocking or other techniques to speed it up. Then if that does not work, we can look at multithreading or operation/dispatch queues to see if that would solve the problem.
    - 

## Processing chain:
- First implementation is going to be probably all in line with the audio queue callback or close to it. Then once that is working, I would like to look at splitting things up into units that take parts of the signal from queues on their own, but still work in a way that is performance optimal.

### Considerations for queue based semi-automatic blocks
- Like gnu radio, can have synchronous (1:1), decimator (N:1), interpolator(1:M), and general (N:M), or completely nondeterministic (?:?) blocks. Queues will most likely connect these together but we want to ensure performance
    - To support nondeterministic blocks, need to use queues to ensure those blocks and pick off and put on to their input and output queues (respectively) at their own whatever rate
    - If we use vectorized operations on these queues, copying memory could be kind of expensive which we will almost surely have to do unless the signal comes in significantly sized chunks that are big enough that we can do vectorized operations on each without a lot of overhead (might be the way to go here)
    - Synchronous blocks are probably the easiest case, can just wait until queue has a large enough amount of items in it (and enforce that chunks of a certain size are contiguous in memory just wrap around) and just vector process the entire thing since it's 1:1
    - Decimator blocks that need to put out chunks of a certain size must wait until the queue has a chunk of N times that size before processing (could result in lots of data accumulating, and resizing/copying if queue was not allocated to be large enough).
    - Interpolator is going to dump a lot of data at once
    - 
