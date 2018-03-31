#include <string.h>
#include <stdio.h>
#include "util.h"

#define LOOP_ITERATIONS 4294967296/59

//#define DEBUG 1
#if DEBUG
    #define debug_printf printf
#else
    void debug_printf(const char* str, ...) {}
#endif

u64 Begin_Time, End_Time, User_Time;
u64 Microseconds;
u64 start_instruction_count, end_instruction_count, user_instruction_count;

u64 read_cycle()
{
	u64 result;
	u32 lower;
	u32 upper1;
	u32 upper2;
	

	asm volatile (
		"repeat_cycle_%=: csrr %0, mcycleh;\n"
		"        csrr %1, mcycle;\n"     
		"        csrr %2, mcycleh;\n"
		"        bne %0, %2, repeat_cycle_%=;\n" 
		: "=r" (upper1),"=r" (lower),"=r" (upper2)
		: 
		: 
	);
	*(u32 *)(&result) = lower;
	*((u32 *)(&result)+1) = upper1;

	return result;
}

u64 read_inst()
{
	u64 result;
	u32 lower;
	u32 upper1;
	u32 upper2;
	
	asm volatile (
		"repeat_inst_%=: csrr %0, minstreth;\n"
		"        csrr %1, minstret;\n"     
		"        csrr %2, minstreth;\n"
		"        bne %0, %2, repeat_inst_%=;\n" 
		: "=r" (upper1),"=r" (lower),"=r" (upper2)
		: 
		: 
	);
	*(u32 *)(&result) = lower;
	*((u32 *)(&result)+1) = upper1;

	return result;
}


#define READ_VALID 0x00008000
u8 get_char() {
    volatile u32 *uart_base = (volatile u32 *)0x60000000;

    while (!(*(uart_base) & READ_VALID));
    return (u8)(*uart_base);
}



//Convert from little-endian to big-endian and vice versa
//Interesting note: on x86_64 gcc will recognize the
//functionality of this code and replace the function
//with the x86_64 bswap instruction
u32 byte_swap (u32 number) {
    u32 result;
    
    result  = 0x000000FF & (number >> 24);
    result |= 0x0000FF00 & (number >> 8);
    result |= 0x00FF0000 & (number << 8);
    result |= 0xFF000000 & (number << 24);

    return result;
}

u32 byte_swap_hw (u32 number) {

    register u32 input asm ("a0");
    input = number;
        
	asm volatile (
		" .byte 0x57, 0x25, 0x05, 0x00;\n"    //machine code for: bswap  a0, a0;
        : "+r" (input)
        : "r" (input)
		:
	);
	debug_printf("result, %d\r\n",input);
    return input;
}

//Count the number of bits that are one
u32 popc (u32 number) {
    u32 result = 0;
    for (u32 i = 0; i < 32; i++) {
        result += (number & 0x1);
        number = number >> 1;
    }
    return result;
}

u32 popc_hw (u32 number) {
    register u32 input asm ("a0");
    input = number;
        
	asm volatile (
		" .byte 0x57, 0x15, 0x05, 0x00;\n"    //machine code for: popc  a0, a0;
        : "+r" (input)
        : "r" (input)
		:
	);
	debug_printf("result, %d\r\n",input);
    return input;
}

//Count how many zero bits there are before the first one bit,
//starting from the most significant bit
u32 count_leading_zeros(u32 number) {
    for (int i = 31; i >=0; i--) {       
        if (number >> i) return 31-i;
    }
    return 32;
}

u32 count_leading_zeros_hw (u32 number) {
    register u32 input asm ("a0");
    input = number;
        
	asm volatile (
		" .byte 0x57, 0x05, 0x05, 0x00;\n"    //machine code for: clz  a0, a0;
        : "+r" (input)
        : "r" (input)
		:
	);
	debug_printf("result, %d\r\n",input);
    return input;
}

//Integer square root using Newton's Method
//Uses the count leading zeros function to create an
//initial guess.  Takes at most 4 iterations, but typically 1 or 2
u32 square_root (u32 number) {
    u32 iterations = 0;
    u32 guess;
    u32 n_over_quess;

    if(number > 1) {
    
        guess = 1 << (16 - count_leading_zeros(number - 1)/2);
        do {
         n_over_quess = number/guess;
         guess = (guess + n_over_quess) / 2;
         iterations++;
        } while (n_over_quess < guess);
        return guess;
        
    } 
    else {
        return number;
    }
}

//Uses hardware count leading zeros
u32 square_root2 (u32 number) {
    u32 iterations = 0;
    u32 guess;
    u32 n_over_quess;

    if(number > 1) {
    
        guess = 1 << (16 - count_leading_zeros_hw(number - 1)/2);
        do {
         n_over_quess = number/guess;
         guess = (guess + n_over_quess) / 2;
         iterations++;
        } while (n_over_quess < guess);
        return guess;
        
    } 
    else {
        return number;
    }
}

u32 square_root_hw (u32 number) {
    register u32 input asm ("a0");
    input = number;
        
	asm volatile (
		" .byte 0x57, 0x35, 0x05, 0x00;\n"    //machine code for: sqrt  a0, a0;
        : "+r" (input)
        : "r" (input)
		:
	);
	debug_printf("result, %d\r\n",input);
    return input;
}

void print_results(u32 result) {
    User_Time = End_Time - Begin_Time;
    user_instruction_count = end_instruction_count - start_instruction_count;

    Microseconds = ((User_Time) * 1000000) / (50000000);

    printf("Begin time: %lld\r\n", Begin_Time);
    printf("End time: %lld\r\n", End_Time);
    printf("User time: %lld\r\n", User_Time);
    printf("Test time in microsecond: %lld\r\n", Microseconds);
    printf("result: %d\r\n", result);
    printf("Begin inst: %lld\r\n", start_instruction_count);
    printf("End inst: %lld\r\n", end_instruction_count);
    printf("User inst: %lld\r\n\r\n", user_instruction_count);
}



int main (int argc, char** argv) {
    u32 cumulative_result;
    u8 response;

    printf("Software Only test, input :0\r\n");
    printf("Hardware Only test, input :1\r\n");
    printf("Software and hardware test, input :2\r\n\r\n");
        
    printf("Please input choice for Count Leading Zeros test:\r\n");
    response = get_char();
    printf("Response was %c:\r\n", response);
    if(response == '0' || response == '2') {
        printf("Starting Count Leading Zeros sw test...\r\n");
        //Sample Counters
        start_instruction_count = read_inst();
        Begin_Time = read_cycle();
        
        cumulative_result = 0;
        for(u32 i=0; i<=LOOP_ITERATIONS; i+=59) {
            cumulative_result += count_leading_zeros(i);
        }
        for(u32 i=0; i<=20; i+=1) {
            cumulative_result += count_leading_zeros(count_leading_zeros(count_leading_zeros(i)));
        }
        //Sample Counters
        End_Time = read_cycle();
        end_instruction_count = read_inst();

        print_results(cumulative_result);
    }
    if(response == '1' || response == '2') {
        printf("Starting Count Leading Zeros hw test...\r\n");
        //Sample Counters
        start_instruction_count = read_inst();
        Begin_Time = read_cycle();
        
        cumulative_result = 0;
        for(u32 i=0; i<=LOOP_ITERATIONS; i+=59) {
        	debug_printf("input, %d, ",i);
            cumulative_result += count_leading_zeros_hw(i);
        }
        for(u32 i=0; i<=20; i+=1) {
            cumulative_result += count_leading_zeros_hw(count_leading_zeros_hw(count_leading_zeros_hw(i)));
        }
        //Sample Counters
        End_Time = read_cycle();
        end_instruction_count = read_inst();

        print_results(cumulative_result);
    }
    
    printf("Please input choice for Population Count test:\r\n");
    response = get_char();
    printf("Response was %c:\r\n", response);
    if(response == '0' || response == '2') {
        printf("Starting population count sw test...\r\n");
        //Sample Counters
        start_instruction_count = read_inst();
        Begin_Time = read_cycle();
        
        cumulative_result = 0;
        for(u32 i=0; i<=LOOP_ITERATIONS; i+=59) {
            cumulative_result += popc(i);
        }
        for(u32 i=0; i<=20; i+=1) {
            cumulative_result += popc(popc(popc(i)));
        }
        //Sample Counters
        End_Time = read_cycle();
        end_instruction_count = read_inst();

        print_results(cumulative_result);
    }
    if(response == '1' || response == '2') {
        printf("Starting population count hw test...\r\n");
        //Sample Counters
        start_instruction_count = read_inst();
        Begin_Time = read_cycle();
        
        cumulative_result = 0;
        for(u32 i=0; i<=LOOP_ITERATIONS; i+=59) {
            debug_printf("input, %d, ",i);
            cumulative_result += popc_hw(i);
        }
        
        for(u32 i=0; i<=20; i+=1) {
            cumulative_result += popc_hw(popc_hw(popc_hw(i)));
        }
        //Sample Counters
        End_Time = read_cycle();
        end_instruction_count = read_inst();

        print_results(cumulative_result);
    }
    
    printf("Please input choice for Swap Bytes test:\r\n");
    response = get_char();
    printf("Response was %c:\r\n", response);
    if(response == '0' || response == '2') {
        printf("Starting swap bytes sw test...\r\n");
        //Sample Counters
        start_instruction_count = read_inst();
        Begin_Time = read_cycle();
        
        cumulative_result = 0;
        for(u32 i=0; i<=LOOP_ITERATIONS; i+=59) {
            cumulative_result += byte_swap(i);
        }
        for(u32 i=0; i<=20; i+=1) {
            cumulative_result += byte_swap(byte_swap(byte_swap(i)));
        }
        //Sample Counters
        End_Time = read_cycle();
        end_instruction_count = read_inst();

        print_results(cumulative_result);
    }
    if(response == '1' || response == '2') {
        printf("Starting swap bytes hw test...\r\n");
        //Sample Counters
        start_instruction_count = read_inst();
        Begin_Time = read_cycle();
        
        cumulative_result = 0;
        for(u32 i=0; i<=LOOP_ITERATIONS; i+=59) {
            debug_printf("input, %d, ",i);
            cumulative_result += byte_swap_hw(i);
        }
        for(u32 i=0; i<=20; i+=1) {
            cumulative_result += byte_swap_hw(byte_swap_hw(byte_swap_hw(i)));
        }
        //Sample Counters
        End_Time = read_cycle();
        end_instruction_count = read_inst();

        print_results(cumulative_result);
    }
  
    printf("Please input choice for square root test:\r\n");
    response = get_char();
    printf("Response was %c:\r\n", response);
    if(response == '0' || response == '2') {
        printf("Starting square root sw test...\r\n");
        //Sample Counters
        start_instruction_count = read_inst();
        Begin_Time = read_cycle();
        
        cumulative_result = 0;
        for(u32 i=0; i<=LOOP_ITERATIONS; i+=59) {
            cumulative_result += square_root(i);
        }
        for(u32 i=0; i<=20; i+=1) {
            cumulative_result += square_root(square_root(square_root(i)));
        }
        //Sample Counters
        End_Time = read_cycle();
        end_instruction_count = read_inst();

        print_results(cumulative_result);
    }
    if(response == '1' || response == '2') {
        printf("Starting square root sw with hw clz test...\r\n");
        //Sample Counters
        start_instruction_count = read_inst();
        Begin_Time = read_cycle();
        
        cumulative_result = 0;
        for(u32 i=0; i<=LOOP_ITERATIONS; i+=59) {
            cumulative_result += square_root2(i);
        }
        for(u32 i=0; i<=20; i+=1) {
            cumulative_result += square_root2(square_root2(square_root2(i)));
        }
        //Sample Counters
        End_Time = read_cycle();
        end_instruction_count = read_inst();

        print_results(cumulative_result);
    
        printf("Starting square root hw test...\r\n");
        //Sample Counters
        start_instruction_count = read_inst();
        Begin_Time = read_cycle();
        
        cumulative_result = 0;
        for(u32 i=0; i<=LOOP_ITERATIONS; i+=59) {
            debug_printf("input, %d, ",i);
            cumulative_result += square_root_hw(i);
        }
        for(u32 i=0; i<=20; i+=1) {
            cumulative_result += square_root_hw(square_root_hw(square_root_hw(i)));
        }
        //Sample Counters
        End_Time = read_cycle();
        end_instruction_count = read_inst();

        print_results(cumulative_result);
    }


  return 0;
}
