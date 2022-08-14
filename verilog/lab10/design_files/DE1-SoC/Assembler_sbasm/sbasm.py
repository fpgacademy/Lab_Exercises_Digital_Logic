import sys
import os
import re


def main():
    argc = len(sys.argv)

    if argc >= 4:
        print('ERROR: Too many arguments.')
        print_usage()
    elif argc <= 1:
        print('ERROR: Too few arguments.')
        print_usage()
    else:
        # Parse the in and out file names from the arguments.
        # Default the output filename to a.mif.
        in_filename = sys.argv[1]
        out_filename = 'a.mif'

        if argc > 2:
            out_filename = sys.argv[2]

        # Create the assembler and assemble.
        a = Assembler(in_filename, out_filename)
        a.assemble()


def print_usage():
    """
    Prints the usage for this script.
    """
    print('Usage: python sbasm.py <input file name> <output file name, default a.mif>')


class ErrorCodes(object):
    """
    Static class for error codes.
    """

    # Error code objects.
    NO_ERROR = 0
    BAD_INSTR = 1
    BAD_REG = 2
    BAD_IMMED = 3
    BIG_IMMED = 4
    BIG_DEFINE = 5
    DEFINE_REDEF = 6
    IMMED_LABEL_NF = 7
    DEPTH_ERROR = 8
    BAD_DATA = 9
    DEPTH_DEFINE = 10
    BIG_BRANCH = 11
    BIG_SHIFT = 12
    UNKNOWN = 13  # Always the last error

    @staticmethod
    def get_error_message(error_code, line, depth, instruction_count):
        """
        Converts the given error code and info into a string message.
        Args:
            error_code: int [NO_ERROR, UNKNOWN]
            line: The line number the error is on
            depth: The depth of the max MIF file
            instruction_count: The current instruction count
        Returns:
            A detailed string for the error.
        """
        error_code = min(error_code, ErrorCodes.UNKNOWN)
        line_str = str(line)

        return {
            ErrorCodes.NO_ERROR: '',
            ErrorCodes.BAD_INSTR: 'ERROR: line ' + line_str + ': cannot parse instruction',
            ErrorCodes.BAD_REG: 'ERROR: line ' + line_str + ': unknown register',
            ErrorCodes.BAD_IMMED: 'ERROR: line ' + line_str +
                                  ': the immediate value for mvt must fit in eight bits',
            ErrorCodes.BIG_IMMED: 'ERROR: line ' + line_str +
                                  ': the immediate value is too large',
            ErrorCodes.BIG_DEFINE: 'ERROR: line ' + line_str + ': define value too large',
            ErrorCodes.DEFINE_REDEF: 'ERROR: line ' + line_str + ': define is being redefined',
            ErrorCodes.IMMED_LABEL_NF: 'ERROR: line ' + line_str +
                                       ': undeclared identifier (label or define), or value error',
            ErrorCodes.DEPTH_ERROR: 'ERROR: Memory depth must be an integer multiple of 2',
            ErrorCodes.BAD_DATA: 'ERROR: line ' + line_str + ': missing or bad data',
            ErrorCodes.DEPTH_DEFINE: 'ERROR: line ' + line_str +
                                     ': symbol DEPTH is reserved, it cannot be redefined',
            ErrorCodes.BIG_BRANCH: 'ERROR: line ' + line_str +
                                   ': the branch target is too large',
            ErrorCodes.BIG_SHIFT: 'ERROR: line ' + line_str +
                                  ': the shift amount is too large',
            ErrorCodes.UNKNOWN: 'ERROR: UNKNOWN'
        }[error_code]


class Assembler(object):
    """
    Assembler class.
    """

    # Define regular expressions patterns that can be used to parse lines of assembly code
    # REGEX to match a single line comment
    COMMENT_REGEX = re.compile('//.*$')

    # REGEX string to match trailing space and a comment
    TRAIL_SPACE_COMMENT = '\s*(//.*)?$'

    # REGEX to match the DEPTH definition
    DEPTH_DEF_REGEX = re.compile('DEPTH\s+(\d+)' + TRAIL_SPACE_COMMENT)

    # REGEX to match a define (.define) statement
    DEFINE_REGEX = re.compile('\.define\s+([a-zA-Z_$][a-zA-Z_$0-9]*)\s+((0|0b|0x|-)?\w+)' +
                              TRAIL_SPACE_COMMENT)

    # REGEX string to match a label only
    LABEL_REGEX_STR = '([a-zA-Z_$][a-zA-Z_$0-9]*):'

    # REGEX to match a label with trailing comment (no trailing instruction)
    LABEL_REGEX = re.compile(LABEL_REGEX_STR + TRAIL_SPACE_COMMENT)

    # REGEX to match instructions. Includes an optional preceeding label and trailing comment
    # type 1 is an instruction with Op2 = register
    INSTR_TYPE1_REGEX = re.compile('(' + LABEL_REGEX_STR + ')?\s*' +
                                   '(mv|add|sub|ld|st|and|cmp)\s+(r[0-7]|pc|sp|lr),\s*\[*(r[0-7]|pc|sp|lr)\]*' + TRAIL_SPACE_COMMENT)
    # type 2 is an instruction with Op2 = #Data
    INSTR_TYPE2_REGEX = re.compile('(' + LABEL_REGEX_STR + ')?\s*' +
                                   '(mv|mvt|add|sub|and|cmp)\s+(r[0-7]|pc|sp|lr),\s*#(((0|0b|0x|-)?\w+)|[a-zA-Z_$][a-zA-Z_$0-9]*)+' +
                                   TRAIL_SPACE_COMMENT)
    # type 3 is a branch instruction
    INSTR_TYPE3_REGEX = re.compile('(' + LABEL_REGEX_STR + ')?\s*' +
                                   '(b(eq|ne|cc|cs|pl|mi|l)?)\s+#*(((0|0b|0x)?\w+)|[a-zA-Z_$][a-zA-Z_$0-9]*)+' +
                                   TRAIL_SPACE_COMMENT)
    # type 4 is a push or pop instruction
    INSTR_TYPE4_REGEX = re.compile('(' + LABEL_REGEX_STR + ')?\s*' +
                                   '(push|pop)\s+(r[0-7])' + TRAIL_SPACE_COMMENT)
    # type 5 is a shift instruction with #Data
    INSTR_TYPE5_REGEX = re.compile('(' + LABEL_REGEX_STR + ')?\s*' +
                                   '(lsl|lsr|asr|ror)\s+(r[0-7]|pc|sp|lr),\s*#(((0|0b|0x|-)?\w+)|[a-zA-Z_$][a-zA-Z_$0-9]*)+' +
                                   TRAIL_SPACE_COMMENT)
    # type 6 is a shift instruction with rY
    INSTR_TYPE6_REGEX = re.compile('(' + LABEL_REGEX_STR + ')?\s*' +
                                   '(lsl|lsr|asr|ror)\s+(r[0-7]|pc|sp|lr),\s*\[*(r[0-7]|pc|sp|lr)\]*' + TRAIL_SPACE_COMMENT)

    # type 7 is an instruction with Op2 = =Data
    INSTR_TYPE7_REGEX = re.compile('(' + LABEL_REGEX_STR + ')?\s*' +
                                   '(mv)\s+(r[0-7]|pc|sp|lr),\s*=(((0|0b|0x|-)?\w+)|[a-zA-Z_$][a-zA-Z_$0-9]*)+' +
                                   TRAIL_SPACE_COMMENT)
    # error check for an instruction that is not ld|st but Op2 = [rY]
    INSTR_TYPE1_CHK_REGEX = re.compile('(' + LABEL_REGEX_STR + ')?\s*' +
                                       '(mv|add|sub|and)\s+(r[0-7]|pc|sp|lr),\s*\[(r[0-7]|pc|sp|lr)\]' + TRAIL_SPACE_COMMENT)

    # REGEX to match .word directive. Includes an optional preceeding label and a
    # trailing comment
    WORD_DIR_REGEX = re.compile('(' + LABEL_REGEX_STR + ')?\s*' + '(.word)\s+((0|0b|0x|-)?\w+)' +
                                TRAIL_SPACE_COMMENT)

    # Max integers
    MAX_INT_16U = 65535  # maximum size of an integer (16 bits)
    MAX_INT_IMM = 0x1FF  # maximum size of immediate data
    MAX_SHIFT = 0xF  # maximum size of shift amount

    # Maps instruction strings to integer values
    # Used for forming machine code words
    INSTR_STR_TO_OPCODE = {'mv': 0, 'b': 1, 'beq': 1, 'bne': 1, 'bcc': 1, 'bcs': 1, 'bpl': 1, 'bmi': 1,
                           'bl': 1, 'mvt': 1, 'add': 2, 'sub': 3, 'ld': 4, 'pop': 4, 'st': 5, 'push': 5, 'and': 6,
                           'cmp': 7, 'lsl': 7, 'lsr': 7, 'asr': 7, 'ror': 7}

    # Maps register strings to integer values. Note: sp = r5, lr = r6, pc = r7
    # Used for forming machine code words
    REG_STR_TO_VAL = {'r0': 0, 'r1': 1, 'r2': 2, 'r3': 3, 'r4': 4, 'r5': 5, 'sp': 5, 'r6': 6,
                      'lr': 6, 'r7': 7, 'pc': 7}

    # Maps condition strings for branches to integer values
    # Used for forming machine code words
    COND_STR_TO_VAL = {'': 0, 'eq': 1, 'ne': 2, 'cc': 3, 'cs': 4, 'pl': 5, 'mi': 6, 'l': 7}

    # Maps shift type to integer values
    # Used for forming machine code words
    SHIFT_STR_TO_VAL = {'lsl': 0, 'lsr': 1, 'asr': 2, 'ror': 3}

    # Used for printing comments at the end of a line of machine code.
    # Indexed with IIIM, where III is the opcode and M is the "immediate" bit.
    INSTR_VAL_TO_STR = {0: 'mv  ', 1: 'mv  ', 2: 'b', 3: 'mvt ', 4: 'add ', 5: 'add ', 6: 'sub ',
                        7: 'sub ', 8: 'ld  ', 9: 'pop ', 10: 'st  ', 11: 'push', 12: 'and ', 13: 'and ',
                        14: 'cmp ', 15: 'cmp '}

    # Maps integers (indices of this list) to register strings
    # Used for printing comments at the end of a line of machine code
    REG_VAL_TO_STR = ['r0', 'r1', 'r2', 'r3', 'r4', 'r5', 'r6', 'r7']

    # Maps integers (indices of this list) to condition strings
    # Used for printing comments at the end of a line of machine code
    SHIFT_VAL_TO_STR = ['lsl', 'lsr', 'asr', 'ror']

    # Maps integers (indices of this list) to shift types
    # Used for printing comments at the end of a line of machine code
    COND_VAL_TO_STR = ['  ', 'eq', 'ne', 'cc', 'cs', 'pl', 'mi', 'l ']

    def __init__(self, in_filename, out_filename):
        """
        Initializes the assembler.
        Args:
            in_filename: The input filename.
            out_filename: The output filname.
        """
        # Store the input filename
        self.in_filename = in_filename

        # Store the outputfilename, default to a.mif
        if out_filename is None:
            out_filename = 'a.mif'
        self.out_filename = out_filename

        # The lines of the input file will be stored here
        self.lines = []

        # Stores the assembled machine instructions
        self.machine_instructions = []

        # Indicates whether a word of machine code is an instruction or data.
        # A value of 0 indicates data
        self.is_inst = []

        # Maps labels and defines to (line) numbers
        self.symbol_def_to_num = {}

        # Width bits (only 16 is currently supported)
        self.width_bits = 16

        # Depth - should correspond to the total number of words in memory
        self.depth_words = 256

        # Tracks current line number of the input file
        self.line = 0

        # Tracks the current instruction number being assembled
        self.curr_instr_num = -1

        # Validate input and output filenames
        if not in_filename.strip() or not os.path.isfile(in_filename):
            print('Input file: ' + in_filename + ' is invalid')
            sys.exit()
        elif not out_filename.strip():
            print('Output file: ' + out_filename + ' is invalid')
            sys.exit()
        else:
            in_file = open(in_filename, 'r')
            self.lines = in_file.read().splitlines()

    def assemble(self):
        """
        Assembles the input file into the output file.
        """
        # validate and parse the in and out filenames.
        self.__validate_out_filename()
        width = 0
        depth = 0
        line = 0

        # Preprocess by finding the labels
        error = self.__find_labels()

        if error is not ErrorCodes.NO_ERROR:
            # Error in preprocess.
            print(ErrorCodes.get_error_message(error, self.line, self.depth_words,
                                               self.curr_instr_num))
        else:
            # Parse the lines of the input file
            error = self.__parse_lines()

            if error is not ErrorCodes.NO_ERROR:
                # Error in processing
                print(ErrorCodes.get_error_message(error, self.line, self.depth_words,
                                                   self.curr_instr_num))
            else:
                # Output the MIF file
                self.__output_file()

    def __find_labels(self):
        """
        Preprocessing - finds all labels and defines
        Returns:
            int: ErrorCodes.BAD_INFILE on error, ErrorCodes.NO_ERROR otherwise
        """
        # Reset the current line and instruction number
        self.line = 1
        self.curr_instr_num = -1

        for line in self.lines:
            line = line.strip()
            match = None

            # Skip empty lines and comments.
            if line != "" and line != "\n" and not self.__is_comment(line):
                # Check matches of REGEXs
                if self.DEPTH_DEF_REGEX.match(line):
                    # Line matches DEPTH line, get the value
                    match = self.DEPTH_DEF_REGEX.match(line)
                    depth = int(match.group(1), 0)

                    # Depth must be a power of 2
                    if depth % 2 != 0:
                        return ErrorCodes.DEPTH_ERROR
                    else:
                        self.depth_words = depth
                elif self.DEFINE_REGEX.match(line):
                    # Line is a define statement
                    match = self.DEFINE_REGEX.match(line)

                    # Get the symbol and the number
                    symbol = match.group(1)
                    num = int(match.group(2), 0)

                    if symbol == 'DEPTH':
                        return ErrorCodes.DEPTH_DEFINE
                    elif symbol in self.symbol_def_to_num:
                        return ErrorCodes.DEFINE_REDEF
                    elif self.__is_number_too_large(num):
                        return ErrorCodes.BIG_DEFINE
                    else:
                        # Add the mapping to the symbol -> value mapping
                        self.symbol_def_to_num[symbol] = num
                elif self.LABEL_REGEX.match(line):
                    # Line is only a label
                    match = self.LABEL_REGEX.match(line)
                    label = match.group(1)

                    if label == 'DEPTH':
                        return ErrorCodes.DEPTH_DEFINE
                    elif label in self.symbol_def_to_num:
                        return ErrorCodes.DEFINE_REDEF
                    else:
                        # Add the mapping to the label -> value mapping
                        self.symbol_def_to_num[label] = self.curr_instr_num + 1
                else:
                    # the rest of the types are parsed in the same way
                    match = self.INSTR_TYPE1_REGEX.match(line)
                    if match is None:
                        match = self.INSTR_TYPE2_REGEX.match(line)
                    if match is None:
                        match = self.INSTR_TYPE3_REGEX.match(line)
                    if match is None:
                        match = self.INSTR_TYPE4_REGEX.match(line)
                    if match is None:
                        match = self.INSTR_TYPE5_REGEX.match(line)
                    if match is None:
                        match = self.INSTR_TYPE6_REGEX.match(line)
                    if match is None:
                        match = self.INSTR_TYPE7_REGEX.match(line)
                    if match is None:
                        match = self.WORD_DIR_REGEX.match(line)

                    if match is None:
                        return ErrorCodes.BAD_INSTR

                    add_to_curr_instr_num = 1
                    if self.INSTR_TYPE7_REGEX.match(line):
                        # type 7 uses two instructions
                        add_to_curr_instr_num = 2
                    # Grab the possible label
                    label = match.group(2)

                    if label == 'DEPTH':
                        return ErrorCodes.DEPTH_DEFINE
                    elif label in self.symbol_def_to_num:
                        return ErrorCodes.DEFINE_REDEF
                    elif label is not None:
                        # Label was defined, add it to the mapping
                        self.symbol_def_to_num[label] = self.curr_instr_num + 1

                    # Increment instruction number
                    self.curr_instr_num += add_to_curr_instr_num
                if match is None:
                    # Line matches nothing, which is bad
                    print("Error: can't parse assembly code on line " + str(self.line))

            # Keep track of line number for error reporting
            self.line += 1
        # ENDFOR

        return ErrorCodes.NO_ERROR

    def __parse_lines(self):
        """
        Processing. Parses the lines of the input file.
        Returns:
            int: ErrorCodes.BAD_INFILE on error, ErrorCodes.NO_ERROR otherwise.
        """
        self.line = 1
        self.curr_instr_num = -1

        for line in self.lines:
            line = line.strip()
            match = None

            # Skip empty lines and comments.
            if line != "" and line != "\n" and not self.__is_comment(line):
                # Only need to parse instructions and .word directives
                if self.INSTR_TYPE1_REGEX.match(line):
                    # Type 1 instruction.
                    (error, sub_mif) = self.__parse_type1_instruction(line)

                    if error == ErrorCodes.NO_ERROR:
                        # Increment instruction number.
                        self.curr_instr_num += 1
                        # Add assembled machine code to the machine instructions
                        self.machine_instructions.extend(sub_mif)
                        self.is_inst.extend([True])
                    else:
                        return error
                elif self.INSTR_TYPE2_REGEX.match(line):
                    (error, sub_mif) = self.__parse_type2_instruction(line)

                    if error == ErrorCodes.NO_ERROR:
                        # Increment instruction number.
                        self.curr_instr_num += 1
                        # Add assembled machine code to the machine instructions
                        self.machine_instructions.extend(sub_mif)
                        self.is_inst.extend([True])
                    else:
                        return error
                elif self.INSTR_TYPE3_REGEX.match(line):
                    (error, sub_mif) = self.__parse_type3_instruction(line)

                    if error == ErrorCodes.NO_ERROR:
                        # Increment instruction number.
                        self.curr_instr_num += 1
                        # Add assembled machine code to the machine instructions
                        self.machine_instructions.extend(sub_mif)
                        self.is_inst.extend([True])
                    else:
                        return error
                elif self.INSTR_TYPE4_REGEX.match(line):
                    (error, sub_mif) = self.__parse_type4_instruction(line)

                    if error == ErrorCodes.NO_ERROR:
                        # Increment instruction number.
                        self.curr_instr_num += 1
                        # Add assembled machine code to the machine instructions
                        self.machine_instructions.extend(sub_mif)
                        self.is_inst.extend([True])
                    else:
                        return error
                elif self.INSTR_TYPE5_REGEX.match(line):
                    (error, sub_mif) = self.__parse_type5_instruction(line)

                    if error == ErrorCodes.NO_ERROR:
                        # Increment instruction number.
                        self.curr_instr_num += 1
                        # Add assembled machine code to the machine instructions
                        self.machine_instructions.extend(sub_mif)
                        self.is_inst.extend([True])
                    else:
                        return error
                elif self.INSTR_TYPE6_REGEX.match(line):
                    (error, sub_mif) = self.__parse_type6_instruction(line)

                    if error == ErrorCodes.NO_ERROR:
                        # Increment instruction number.
                        self.curr_instr_num += 1
                        # Add assembled machine code to the machine instructions
                        self.machine_instructions.extend(sub_mif)
                        self.is_inst.extend([True])
                    else:
                        return error
                elif self.INSTR_TYPE7_REGEX.match(line):
                    (error, sub_mif) = self.__parse_type7_instruction(line)

                    if error == ErrorCodes.NO_ERROR:
                        # Increment instruction number.
                        self.curr_instr_num += len(sub_mif)
                        # Add assembled machine code to the machine instructions
                        # Type 7 produces two words of machine code (mvt, add)
                        self.machine_instructions.extend(sub_mif)
                        self.is_inst.extend([True,True])
                    else:
                        return error
                elif self.WORD_DIR_REGEX.match(line):
                    # .word directive
                    (error, sub_mif) = self.__parse_word_dir(line)

                    if error == ErrorCodes.NO_ERROR:
                        # Increment instruction number.
                        self.curr_instr_num += 1
                        # Add assembled machine code to the machine instructions
                        self.machine_instructions.extend(sub_mif)
                        # put False into is_inst array to indicate data item
                        self.is_inst.extend([False])
                    else:
                        return error

            # Move to the next line.
            self.line += 1
        # ENDFOR

        return ErrorCodes.NO_ERROR

    def __output_file(self):
        """
        Outputs the machine instructions to the output mif file.
        """
        # Open file for writing, should already be verified.
        out_file = open(self.out_filename, 'w')

        ####################################################
        ## MIF Data.
        out_file.write('WIDTH = ' + str(self.width_bits) + ';\n')
        out_file.write('DEPTH = ' + str(self.depth_words) + ';\n')
        out_file.write('ADDRESS_RADIX = HEX;\n')
        out_file.write('DATA_RADIX = HEX;\n\n')
        out_file.write('CONTENT\nBEGIN\n')

        ########################
        ## Instructions.
        instruction_num = 0
        instruction_format_str = '%0' + str(self.width_bits / 4) + 'x'
        i = 0

        while i < len(self.machine_instructions):
            # Get the current instruction.
            machine_code = self.machine_instructions[i]
            instruction = self.is_inst[i]

            # Format the instruction number and the instruction itself (HEX).
            instruction_num_str = '%x' % i
            instruction_str = instruction_format_str % (machine_code)

            # Write to the output file, format - <inst #>    : <inst>;    % inst comment.
            if instruction:
                # Convert the current instruction into a comment.
                comment_str = self.__instruction_to_comment(i, machine_code)
                out_file.write(instruction_num_str + '\t\t: ' + instruction_str + ';\t\t% ' +
                               comment_str + '\n')
            else:
                if (machine_code >= 0):  # data is positive
                    out_file.write(instruction_num_str + '\t\t: ' + instruction_str + ';\t\t% ' +
                                   'data %\n')
                else:  # data is negative; make 2's complement manually
                    machine_code = -machine_code
                    machine_code = (machine_code ^ 0xFFFF) + 1
                    instruction_str = instruction_format_str % (machine_code)
                    out_file.write(instruction_num_str + '\t\t: ' + instruction_str + ';\t\t% ' +
                                   'data %\n')

            # Move to the next instruction.
            i += 1

        # ENDWHILE
        ########################

        out_file.write('END;\n')
        ####################################################

    def __validate_out_filename(self):
        """
        Validates the output filename. Appends a '.mif' extension if it is missing.
        """
        if not self.out_filename.endswith('.mif'):
            self.out_filename += '.mif'

    def __is_comment(self, line):
        """
        Determines if a line is a comment.
        Returns:
            Boolean: True if the line is a comment, False otherwise.
        """
        return self.COMMENT_REGEX.match(line)

    def __parse_type1_instruction(self, line):
        """
        Parses a type 1 instruction (no immediate data)
        Args:
            line: The line from the input file which matched the INSTR_TYPE1_REGEX.
        Returns:
            int: ErrorCodes.NO_ERROR on success, some error code on failure.
            [int]: An array of MIF instructions which is the assembled machine code.
        """
        # error check to see if instruction uses [rY] but is not ld or st
        if self.INSTR_TYPE1_CHK_REGEX.match(line):
            return ErrorCodes.BAD_INSTR, []
        match = self.INSTR_TYPE1_REGEX.match(line)

        # Grab the instruction and registers from the REGEX.
        opcode = self.INSTR_STR_TO_OPCODE.get(match.group(3))
        rX = self.REG_STR_TO_VAL.get(match.group(4))
        rY = self.REG_STR_TO_VAL.get(match.group(5))

        if opcode is None:
            return ErrorCodes.BAD_INSTR, []
        elif rX is None:
            return ErrorCodes.BAD_REG, []
        elif rY is None:
            return ErrorCodes.BAD_REG, []
        else:
            # Create the instruction and return it.
            mif_instr = self.__make_type1_instruction(opcode, rX, rY)
            return ErrorCodes.NO_ERROR, [mif_instr]

    def __parse_type2_instruction(self, line):
        """
        Parses a type 2 instruction (#immediate operand).
        Args:
            line: The line from the input file which matched the INSTR_TYPE2_REGEX.
        Returns:
            int: ErrorCodes.NO_ERROR on success, some error code on failure.
            [int]: An array of MIF instructions which is the assembled machine code.
        """
        match = self.INSTR_TYPE2_REGEX.match(line)
        # Grab the instruction, register and immediate value from the REGEX.
        opcode = self.INSTR_STR_TO_OPCODE.get(match.group(3))
        rX = self.REG_STR_TO_VAL.get(match.group(4))
        imm_str = match.group(5)
        imm = None
        try:
            imm = int(imm_str, 0)
        except ValueError:
            # see if the immediate is a valid symbolic name
            imm = self.symbol_def_to_num.get(imm_str)
            if imm is None:
                return ErrorCodes.IMMED_LABEL_NF, []

        # error check the value of the immediate constant
        if match.group(3) == 'mvt':
            if self.__is_number_bad_imm(imm):
                return ErrorCodes.BAD_IMMED, []
        else:
            # any other instruction with immediate data
            if self.__is_number_too_large_imm(imm):
                return ErrorCodes.BIG_IMMED, []

        if opcode is None:
            return ErrorCodes.BAD_INSTR, []
        elif rX is None:
            return ErrorCodes.BAD_REG, []
        else:
            mif_instr = self.__make_type2_instruction(match.group(3), opcode, rX, imm)
            return ErrorCodes.NO_ERROR, [mif_instr]

    def __parse_type3_instruction(self, line):
        """
        Parses a type 3 instruction (branch).
        Args:
            line: The line from the input file which matched the INSTR_TYPE3_REGEX.
        Returns:
            int: ErrorCodes.NO_ERROR on success, some error code on failure.
            [int]: An array of MIF instructions which is the assembled machine code.
        """
        match = self.INSTR_TYPE3_REGEX.match(line)

        # Grab the instruction, condition and branch address from the REGEX
        opcode = self.INSTR_STR_TO_OPCODE.get(match.group(3))
        cond = match.group(4)
        if cond is not None:
            cond = self.COND_STR_TO_VAL.get(match.group(4))
        else:
            cond = self.COND_STR_TO_VAL.get('')
        address = match.group(5)
        imm = None
        try:
            imm = int(address, 0)
        except ValueError:
            # see if the immediate is a valid symbolic name
            imm = self.symbol_def_to_num.get(address)
            if imm is None:
                return ErrorCodes.IMMED_LABEL_NF, []

        # error check the value of the immediate constant (#Label)
        if imm >= self.depth_words:
            return ErrorCodes.BIG_BRANCH, []

        if opcode is None:
            return ErrorCodes.BAD_INSTR, []
        # Create the instruction and return it with the immediate value.
        mif_instr = self.__make_type3_instruction(opcode, cond, imm)
        return ErrorCodes.NO_ERROR, [mif_instr]

    def __parse_type4_instruction(self, line):
        """
        Parses a type 4 instruction (push or pop)
        Args:
            line: The line from the input file which matched the INSTR_TYPE4_REGEX.
        Returns:
            int: ErrorCodes.NO_ERROR on success, some error code on failure.
            [int]: An array of MIF instructions which is the assembled machine code.
        """
        match = self.INSTR_TYPE4_REGEX.match(line)

        # Grab the instruction and registers from the REGEX.
        opcode = self.INSTR_STR_TO_OPCODE.get(match.group(3))
        rX = self.REG_STR_TO_VAL.get(match.group(4))
        rY = 5  # register r5 is the sp

        if opcode is None:
            return ErrorCodes.BAD_INSTR, []
        elif rX is None:
            return ErrorCodes.BAD_REG, []
        else:
            # Create the instruction and return it.
            mif_instr = self.__make_type4_instruction(opcode, rX, rY)
            return ErrorCodes.NO_ERROR, [mif_instr]

    def __parse_type5_instruction(self, line):
        """
        Parses a type 5 instruction (shift with #immediate operand).
        Args:
            line: The line from the input file which matched the INSTR_TYPE5_REGEX.
        Returns:
            int: ErrorCodes.NO_ERROR on success, some error code on failure.
            [int]: An array of MIF instructions which is the assembled machine code.
        """
        match = self.INSTR_TYPE5_REGEX.match(line)
        # Grab the instruction, register and immediate value from the REGEX.
        opcode = self.INSTR_STR_TO_OPCODE.get(match.group(3))
        rX = self.REG_STR_TO_VAL.get(match.group(4))
        imm_str = match.group(5)
        imm = None
        try:
            imm = int(imm_str, 0)
        except ValueError:
            # see if the immediate is a valid symbolic name
            imm = self.symbol_def_to_num.get(imm_str)
            if imm is None:
                return ErrorCodes.IMMED_LABEL_NF, []

        # check shift operand size
        if self.__is_shift_too_large_imm(imm):
            return ErrorCodes.BIG_SHIFT, []

        if opcode is None:
            return ErrorCodes.BAD_INSTR, []
        elif rX is None:
            return ErrorCodes.BAD_REG, []
        else:
            mif_instr = self.__make_type5_instruction(match.group(3), opcode, rX, imm)
            return ErrorCodes.NO_ERROR, [mif_instr]

    def __parse_type6_instruction(self, line):
        """
        Parses a type 6 instruction (shift with rY).
        Args:
            line: The line from the input file which matched the INSTR_TYPE6_REGEX.
        Returns:
            int: ErrorCodes.NO_ERROR on success, some error code on failure.
            [int]: An array of MIF instructions which is the assembled machine code.
        """
        match = self.INSTR_TYPE6_REGEX.match(line)
        # Grab the instruction and registers from the REGEX.
        opcode = self.INSTR_STR_TO_OPCODE.get(match.group(3))
        rX = self.REG_STR_TO_VAL.get(match.group(4))
        rY = self.REG_STR_TO_VAL.get(match.group(5))

        if opcode is None:
            return ErrorCodes.BAD_INSTR, []
        elif rX is None:
            return ErrorCodes.BAD_REG, []
        elif rY is None:
            return ErrorCodes.BAD_REG, []
        else:
            # Create the instruction and return it.
            mif_instr = self.__make_type6_instruction(match.group(3), opcode, rX, rY)
            return ErrorCodes.NO_ERROR, [mif_instr]

    def __parse_type7_instruction(self, line):
        """
        Parses a type 7 instruction (=immediate operand).
        Args:
            line: The line from the input file which matched the INSTR_TYPE7_REGEX.
        Returns:
            int: ErrorCodes.NO_ERROR on success, some error code on failure.
            [int]: An array of MIF instructions which is the assembled machine code.
        """
        match = self.INSTR_TYPE7_REGEX.match(line)
        # Grab the instruction, register and immediate value from the REGEX.
        opcode = self.INSTR_STR_TO_OPCODE.get(match.group(3))
        rX = self.REG_STR_TO_VAL.get(match.group(4))
        imm_str = match.group(5)
        imm = None
        try:
            imm = int(imm_str, 0)
        except ValueError:
            # see if the immediate is a valid symbolic name
            imm = self.symbol_def_to_num.get(imm_str)
            if imm is None:
                return ErrorCodes.IMMED_LABEL_NF, []

        # error check the value of the =immediate constant
        if self.__is_number_too_large(imm):
            return ErrorCodes.BIG_IMMED, []

        if opcode is None:
            return ErrorCodes.BAD_INSTR, []
        elif rX is None:
            return ErrorCodes.BAD_REG, []
        else:
            mif_instr0, mif_instr1 = self.__make_type7_instruction(match.group(3), opcode, rX, imm)
            return ErrorCodes.NO_ERROR, [mif_instr0, mif_instr1]

    def __make_type1_instruction(self, opcode, rX, rY):
        """
        Converts an instruction to machine code.
        Args:
            opcode: the instruction int.
            rX: The first register int.
            rY: The second register int.
        Returns:
            int: The machine code for the instruction.
        """
        # data processing inst = III0XXX000000YYY, III = opcode, XXX = rX, YYY = rY
        return rY | (rX << 9) | (opcode << 13)

    def __make_type2_instruction(self, instr, opcode, rX, imm):
        """
        Converts an instruction to machine code.
        Args:
            opcode: the instruction int.
            rX: The first register int.
            imm: The immediate data
        Returns:
            int: The machine code for the instruction.
        """
        # data processing inst = III1XXXDDDDDDDDD, III = opcode, XXX = rX, DDDDDDDDD = #D
        if not instr == 'mvt':
            return (imm & 0x1FF) | (rX << 9) | (1 << 12) | (opcode << 13)
        else:
            return (imm) | (rX << 9) | (1 << 12) | (opcode << 13)

    def __make_type3_instruction(self, opcode, cond, imm):
        """
        Converts an instruction to machine code.
        Args:
            opcode: the instruction int. for branch
            cond: The branch condition int.
            imm: The immediate data
        Returns:
            int: The machine code for the instruction.
        """
        # b{cond} = III0 CCC DDDDDDDDD, where III = 001, CCC = cond
        offset = imm - ((self.curr_instr_num + 1) + 1);
        if offset > 0:
            return offset | (cond << 9) | (opcode << 13)
        else:
            # make a 9-bit 2's-complement value
            value = (((0xFFFF ^ -offset) + 1) & 0x1FF)
            return value | (cond << 9) | (opcode << 13)
        # return (imm & 0x1FF) | (cond << 9) | (opcode << 13)

    def __make_type4_instruction(self, opcode, rX, rY):
        """
        Converts an instruction to machine code.
        Args:
            opcode: the instruction int.
            rX: The first register int.
            rY: The second register int.
        Returns:
            int: The machine code for the instruction.
        """
        # push, pop = III1 XXX 000000YYY, where III = 100 (pop) or 101 (push), XXX = rX, YYY = rY
        return rY | (rX << 9) | (1 << 12) | (opcode << 13)

    def __make_type5_instruction(self, instr, opcode, rX, imm):
        """
        Converts an instruction to machine code.
        Args:
            opcode: the instruction int.
            rX: The first register int.
            imm: The immediate data
        Returns:
            int: The machine code for the instruction.
        """
        # shift inst = III0XXX11SS0DDDD, III = opcode, XXX = rX, SS = type, DDDD = shift amount
        shift_type = self.SHIFT_STR_TO_VAL.get(instr)
        return (imm & 0xF) | (shift_type << 5) | (1<<7) | (1<<8) | (rX << 9) | (opcode << 13)

    def __make_type6_instruction(self, instr, opcode, rX, rY):
        """
        Converts an instruction to machine code.
        Args:
            opcode: the instruction int.
            rX: The first register int.
            rY: The second register int.
        Returns:
            int: The machine code for the instruction.
        """
        # shift inst = III0XXX10SS00YYY, III = opcode, XXX = rX, SS = type, YYY = rY
        shift_type = self.SHIFT_STR_TO_VAL.get(instr)
        return rY | (shift_type << 5) | (1<<8) | (rX << 9) | (opcode << 13)

    def __make_type7_instruction(self, instr, opcode, rX, imm):
        """
        Converts an instruction to machine code.
        Args:
            opcode: the instruction int.
            rX: The first register int.
            imm: The immediate data
        Returns:
            int: An array with the machine code for the instructions
        """
        # data processing inst = III1XXXDDDDDDDDD, III = opcode, XXX = rX, DDDDDDDDD = #D
        # data processing inst = III0XXX000000YYY, III = opcode, XXX = rX, YYY = rY
        opcode1 = self.INSTR_STR_TO_OPCODE.get('mvt')
        opcode2 = self.INSTR_STR_TO_OPCODE.get('add')
        inst1 = (imm >> 8 & 0xFF) | (rX << 9) | (1 << 12) | (opcode1 << 13)
        inst2 = (imm & 0xFF) | (rX << 9) | (1 << 12) | (opcode2 << 13)
        return inst1, inst2

    def __parse_word_dir(self, line):
        """
        Parses a .word directive
        Args:
            line: The line from the input file which matched the WORD_DIR_REGEX.
        Returns:
            int: ErrorCodes.NO_ERROR on success, some error code on failure.
            [int]: An array of MIF instructions which is the assembled machine code.
        """
        match = self.WORD_DIR_REGEX.match(line)
        data_str = match.group(4)

        # Grab the instruction and registers from the REGEX.
        try:
            data = int(data_str, 0)
        except ValueError:
            return ErrorCodes.BAD_DATA, []

        return ErrorCodes.NO_ERROR, [data]

    def __is_shift_too_large_imm(self, num):
        """
        Determines if a number is too large for the shift amount.
        Args:
            num: The number to check.
        Returns:
            Boolean: True if the number is too large.
        """
        return num > self.MAX_SHIFT

    def __is_number_too_large(self, num):
        """
        Determines if a number is too large for the architecture.
        Args:
            num: The number to check.
        Returns:
            Boolean: True if the number is too large.
        """
        return num > self.MAX_INT_16U

    def __is_number_too_large_imm(self, num):
        """
        Determines is a number is too large for the architecture.
        Args:
            num: The number to check.
        Returns:
            Boolean: True if the number is too large.
        """
        test = num & 0xFF00
        if (test == 0):  # check limit for +ve value
            return False
        test = test ^ 0xFF00
        if (test == 0):  # check limit for -ve value
            return False
        else:
            return True

    def __is_number_bad_imm(self, num):
        """
        Determines is a number is inappropriate for the mvt instruction
        Args:
            num: The number to check.
        Returns:
            Boolean: True if the number is too large.
        """
        return (num & 0xFF00) != 0

    def __instruction_to_comment(self, line, machine_code):
        """
        Converts an instruction to a comment.
        Args:
            instr: The current instruction.
        Returns:
            str: The string form of the instruction.
        """
        # Parse out the instruction and first and second registers.
        rY = machine_code & 0x0007
        rX = (machine_code >> 9) & 0x0007
        imm = (machine_code >> 12) & 0x0001
        i = (machine_code >> 13) & 0x0007
        # Parse out the condition for a branch
        cond = (machine_code >> 9) & 0x0007
        # Parse bits for a shift instruction
        shift_flag = (machine_code >> 8) & 0x0001
        imm_shift = (machine_code >> 7) & 0x0001
        shift_type = (machine_code >> 5) & 0x0003
        shift_amount = machine_code & 0x000F

        # shift inst = III0XXX1SS00DDDD, III = opcode, XXX = rX, SS = type, DDDD = shift amount

        # Create the comment for branch instructions
        instr = self.INSTR_VAL_TO_STR[(i << 1) + imm];
        D = machine_code & 0x1FF  # immediate data
        if instr == 'b':
            comment = instr + self.COND_VAL_TO_STR[cond] + '  '

            target = line + 1  # calculate branch target
            if (D & 0xFF00) == 0:
                target += D  # positive offset
            else:
                target -= ((D ^ 0x1FF) + 1)  # negative offset
            comment += '0x%x' % (target)
        elif instr == 'cmp ' and imm == 0 and shift_flag == 1:
            # this is not a cmp, it is a shift
            instr = self.SHIFT_VAL_TO_STR[shift_type]; # change cmp to "shift"
            comment = instr + '  ' + self.REG_VAL_TO_STR[rX]
            if imm_shift == 1:
                comment += ', ' + '#0x%01x' % (shift_amount)
            else:
                comment += ', ' + self.REG_VAL_TO_STR[rY]
        else:
            comment = instr + ' ' + self.REG_VAL_TO_STR[rX]

            if instr == 'ld  ' or instr == 'st  ':
                comment += ', ' + '[' + self.REG_VAL_TO_STR[rY] + ']'
            elif instr != 'push' and instr != 'pop ':
                # Append the immediate value if used
                if imm == 1:
                    if instr != 'mvt ':
                        if D & 0xFF00:
                            D |= 0xFF00
                        comment += ', ' + '#0x%04x' % (D)
                    else:
                        comment += ', ' + '#0x%04x' % (D)
                else:
                    comment += ', ' + self.REG_VAL_TO_STR[rY]

        comment += ' %'
        return comment


if __name__ == "__main__":
    main()
