//
//  Filter.swift
//  Modulator
//
//  Created by James on 8/21/16.
//  Copyright © 2016 dimnsionofsound. All rights reserved.
//


import Foundation
import Accelerate

class ComplexFIRFilter {
    var kernel: SplitComplex
    fileprivate var overlapBuffer : SplitComplex
    var fftSetup: FFTSetup
    var fftSetupSize: Int
    var kernelFftStorage: [Int: SplitComplex]
    
    init(kernel: SplitComplex) {
        self.kernel = kernel
        overlapBuffer = SplitComplex(count: kernel.count - 1)
        fftSetupSize = max(12, fftSize(forCount: kernel.count))
        
        fftSetup = vDSP_create_fftsetup(vDSP_Length(fftSetupSize),
                                        FFTRadix(kFFTRadix2))!
        
        kernelFftStorage = [Int: SplitComplex]()
    }
    
    /* Create an FIRFilter using an arbitrary window. */
    convenience init(filterType: FilterType,
                     length: Int,
                     fs: Int,
                     cutoff: Float,
                     window: [Float],
                     center: Float) {
        assert(length == window.count)
        
        var sincImpulse
            = SplitComplex(real: sinc(length, fs: Float(fs), cutoff: cutoff))
        
        if (filterType == FilterType.lowpass) {
            
            let s = sincImpulse * window
            self.init(kernel: s)
            
        } else if (filterType == FilterType.bandpass) {
            
            assert(center != 0.0)
            let modulation = cosine(length, fs: Float(fs),
                                    fc: center, centered: true)
            var s = sincImpulse * modulation
            s = s * window
            self.init(kernel: s)
            
        } else if (filterType == FilterType.highpass) {
            
            var modulation = cosine(length, fs: Float(fs),
                                    fc: Float(fs)/2, centered: false)
            
            var s = sincImpulse * modulation
            s = s * window
            self.init(kernel: s)
            
        } else if (filterType == FilterType.complexbandpass) {
            
            var modulation = complexExponential(length,
                                                fs: Float(fs),
                                                fc: center,
                                                centered: true)
            
            var s = modulation * sincImpulse
            s = s * window
            self.init(kernel: s)
            
        } else {
            
            self.init(kernel: SplitComplex(count:1))
            
        }
    }
    
    /* Create an FIR filter using a hann-windowed Sinc function. */
    convenience init(filterType: FilterType,
                     length: Int,
                     fs: Int,
                     cutoff: Float) {
        
        assert(filterType != FilterType.bandpass)
        
        let window = hann(length)
        self.init(filterType: filterType,
                  length: length,
                  fs: fs,
                  cutoff:cutoff,
                  window: window,
                  center: 0)
    }
    
    
    convenience init(filterType: FilterType,
                     length: Int,
                     fs: Int,
                     cutoff: Float,
                     center: Float) {
        
        let window = hann(length)
        self.init(filterType: filterType,
                  length: length,
                  fs: fs,
                  cutoff:cutoff,
                  window: window,
                  center: center)
    }
    
    
    /* Computes or retrieves an already computed FFT of size
     FORLOG2SIZE of the kernel of this FIRFilter. */
    func getKernelFft(forLog2Size: Int) -> DSPSplitComplex {
        
        if let returnValue = kernelFftStorage[forLog2Size] {
            
            return returnValue.dspSC
            
        } else {
            let bufferSize = 1 << forLog2Size
            let thisFftSetup : FFTSetup = getFftSetup(forLog2Size: forLog2Size)
            
            var input = SplitComplex(sp: kernel,
                                     count: bufferSize)
            
            /* These will store the Frequency domain version of the kernel */
            var output = SplitComplex(count: bufferSize)
            
            /* Make sure ARC knows not to throw away the arrays */
            kernelFftStorage[forLog2Size] = output
            
            /* Do the actual FFT */
            vDSP_fft_zop(thisFftSetup,
                          &input.dspSC,     1,
                          &output.dspSC,        1,
                          vDSP_Length(forLog2Size), 1)
            
            return output.dspSC
        }
    }
    
    /* Computes or retrieves and already computed FFTSetup of size at least
     FORLOG2SIZE. */
    func getFftSetup(forLog2Size: Int) -> FFTSetup {
        if (fftSetupSize >= forLog2Size) {
            
            return fftSetup
            
        } else {
            
            fftSetupSize = forLog2Size
            fftSetup = vDSP_create_fftsetup(vDSP_Length(forLog2Size),
                                            FFTRadix(kFFTRadix2))!
            return fftSetup
            
        }
    }
    
    /* Filter a set of inputSamples using the overlap-add method. Input may be
     mutated during execution but will be in its original state when finished.
     */
    func filter(_ inputSamples: SplitComplex) -> SplitComplex {

        var outputSamples : SplitComplex
        
        let originalInputLength = inputSamples.count
        let fullLength = inputSamples.count + kernel.real.count - 1
        var tempOutBuffer = SplitComplex(repeating: 0.0 , count: fullLength)
        
        /* Do FFT Convolution */
      
        let thisFftSize : Int
            = fftSize(forCount: originalInputLength + kernel.real.count - 1)
        
        /* Make sure FFTSetup is big enough */
        let thisFftSetup = getFftSetup(forLog2Size: thisFftSize)
        let bufferLength = 1 << thisFftSize;
        
        /* Create array for FFT of input */
        var paddedInput = SplitComplex(sp: inputSamples, count: bufferLength)
        
        /* Retrieve FFT of kernel */
        var kernelFrDomain : DSPSplitComplex
            = getKernelFft(forLog2Size: thisFftSize)
        
        /* Create space for the FFT of the input samples */
        var inputFrDomain = SplitComplex(count: bufferLength)
        
        /* Do the FFT of the input. */
        vDSP_fft_zop(thisFftSetup,
                      paddedInput.dspSCConst,   1,
                      &inputFrDomain.dspSC,     1,
                      vDSP_Length(thisFftSize), 1)
        
        /* Now multiply pointwise the Kernel FFT and the input data FFT
        
         Put it in the old paddedInput to save a bit (heh) of memory
         Trying to save memory here but it does look slightly more confusing. */
        
        inputFrDomain.testPtrMatch()
        
        vDSP_zvmul(inputFrDomain.dspSCConst,    1,
                   &kernelFrDomain,             1,
                   &paddedInput.dspSC,          1,
                   vDSP_Length(bufferLength), 1)
        
        /* Now do the Inverse FFT to get back the convolved data
         Put the packed data into one of the arrays we already have
         inputFrDomain */
        
        vDSP_fft_zop(thisFftSetup,
                      paddedInput.dspSCConst,   1,
                      &inputFrDomain.dspSC,     1,
                      vDSP_Length(thisFftSize), -1)
        
        /* Scale the output back down to it's mathematical value. */
        var scalingFactor : Float = 1.0 / (Float(bufferLength))
        tempOutBuffer = inputFrDomain * scalingFactor
        
        /* Add the overlapped samples from last time. */
        for outputIndex in 0..<kernel.count - 1 {
            tempOutBuffer[outputIndex] += overlapBuffer[outputIndex]
        }
        
        /* Save the end of the output here for use in the next operation */
        overlapBuffer = tempOutBuffer[originalInputLength, fullLength]
        outputSamples = tempOutBuffer[0, originalInputLength]
        return outputSamples
    }

}

