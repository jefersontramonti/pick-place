# Creating SCL Programs — TIA Portal
> Manual 21.00.00.00 | November 2025  
> Source: https://docs.tia.siemens.cloud  
> © Siemens 2026. All rights reserved.

---


This section contains information on the following topics:
Basics of SCL
Settings for SCL
The programming window of SCL
Entering SCL instructions
Editing SCL instructions
SCL programming examples


## 1.1 Basics of SCL


### 1.1.1 Programming language SCL


Programming language SCL
SCL (Structured Control Language) is a high-level programming language based on PASCAL. The
language is based on DIN EN 61131-3 (international IEC 1131-3).
The standard standardizes programming languages for programmable logic controllers. The SCL
programming language fulfills the PLCopen Basis Level of ST language (Structured Text) defined
in this standard.

Language elements
SCL also contains higher programming languages in addition to the typical elements of the PLC,
such as inputs, outputs, timers or memory bits.
Expressions
Value assignments
Operators

Program control
SCL provides convenient instructions for controlling the program allowing you, for example, to
create program branches, loops or jumps.

Application


SCL is therefore particularly suitable for the following areas of application:
Data management
Process optimization
Recipe management
Mathematical / statistical tasks


### 1.1.2 Expressions


Description
Expressions are calculated during the runtime of the program and return a value. An expression
consists of operands (such as constants, tags or function calls) and optionally out of operators
(such as *, /, + or -). Expressions can be linked together or nested within each other by
operators.

Evaluation order
The evaluation of the expression occurs in a specific order that is defined by the following
factors:
Priority of the operators involved
Left-to-right order
Brackets
Within an expression, do not use function calls that influence global or static tags.

Types of expressions
The following expression types are available depending on the operator:
Arithmetic expressions
Arithmetic expressions consist of either a numerical value or combine two values or
expressions with arithmetic operators.
Relational expressions
Relational expressions compare the values of two operands and yield a Boolean value. The
result is TRUE if the comparison is true, and FALSE if it is not met.
Logical expressions
Logical expressions combine two operands with logical operators (AND, OR, XOR) or
negating operands (NOT).

How expressions are used
You can use the result of an expression in different ways:
As a value assignment for a tag


As as a condition for a control instruction
As a parameter for a calling a block or instruction
See also
Operators and operator precedence
Arithmetic expressions
Relational expressions
Logical expressions


### 1.1.3 Arithmetic expressions


Description
Arithmetic expressions consist of either a numerical value or combine two values or expressions
with arithmetic operators.
Arithmetic operators can process the data types that are allowed in the CPU in use. If two
operands are involved in the operation, the data type of the result is determined based on the
following criteria:
If both operands are integers with sign and have different lengths, the result receives the
data type of the longer integer (e. g. INT + DINT = DINT).
If both operands are integers without sign and have different lengths, the result receives the
data type of the longer integer (e. g. USINT + UDINT = UDINT).
If one operand is an integer with sign and the other integer is an operand without sign, the
result receives the next larger data type with sign that covers the integer without sign (e. g.
SINT + USINT = INT).
You can only execute an operation with such operands if the IEC check is not set.
If one operand is an integer and the other operand is a floating-point number, the result
receives the data type of the floating-point number (e. g. INT + REAL = REAL).
If both operands are floating-point numbers and have different lengths, the result receives
the data type of the longer floating-point number (e. g. REAL + LREAL = LREAL).
The data type of the result of an operation that involves operands of the data type groups
"Times" and "Date and time" can be found in the table in section "Data types of arithmetic
expressions".
You cannot use data types of the data type groups "Times" and "Date and time" when the
IEC check is set.

Data types of arithmetic expressions
The following table shows the data types you can use in arithmetic expressions:
Operation


Operator

1st operand

2nd operand

Result


Power

Unary plus

Unary minus

Multiplication

Division

**

+

-

*

/

Integer/floating-

Integer/floating-

Floating-point

point number

point number

number

Integer/floating-

-

Integer/floating-

point number

point number

TIME, LTIME

TIME, LTIME

Integer/floating-

-

Integer/floating-

point number

point number

TIME, LTIME

TIME, LTIME

Integer/floating-

Integer/floating-

Integer/floating-

point number

point number

point number

TIME, LTIME

Integer

TIME, LTIME

Integer/floating-

Integer/floating-

Integer/floating-

point number

point number (not

point number

equal 0)

Modulo

TIME, LTIME

Integer

TIME, LTIME

MOD

Integer

Integer

Integer

+

Integer/floating-

Integer/floating-

Integer/floating-

point number

point number

point number

TIME

TIME

TIME

TIME

DINT

TIME

LTIME

TIME, LTIME

LTIME

LTIME

LINT

LTIME

TOD

TIME

TOD

TOD

DINT

TOD

LTOD

TIME, LTIME

LTOD

function
Addition


Addition

+

LTOD

LINT

LTOD

DATE

LTOD

DTL

DATE

TOD

S7-300/400: DT
S7-1200/1500:
DTL

Subtraction

-

DT

TIME

DT

LDT

TIME, LTIME

LDT

DTL

TIME, LTIME

DTL

Integer/floating-

Integer/floating-

Integer/floating-point

point number

point number

number

TIME

TIME

TIME

TIME

DINT

TIME

LTIME 1)

TIME, LTIME

LTIME

LTIME

LINT

LTIME

TOD

TIME

TOD

TOD

DINT

TOD

TOD

TOD

TIME

LTOD

TIME, LTIME

LTOD

LTOD

LINT

LTOD

LTOD

LTOD

LTIME

DATE

DATE

S7-300/400/1200:
TIME
S7-1500: LTIME


Subtraction

-

DT

TIME

DT

DT

DT

TIME

LDT

TIME, LTIME

LDT

DTL

TIME, LTIME

DTL

DTL

DTL

S7-1200: TIME
S7-1500: LTIME

1) Combinations between nanoseconds and milliseconds are not possible within

expressions.
For additional information on valid data types, refer to "See also".

Example
The following example shows an arithmetic expression:


```scl
"MyTag1":= "MyTag2" * "MyTag3";
```

See also
Expressions
Operators and operator precedence
Overview of the valid data types


### 1.1.4 Relational expressions


Description
Relational expressions compare the values or the data types of two operands and yield a
Boolean value. The result is TRUE if the comparison is true, and FALSE if it is not met.
Relational operators can process the data types that are allowed in the CPU in use. The data type
of the result always is BOOL.
Note the following rules when forming relational expressions:
All tags are comparable within the following data type groups:
- Integers/floating-point numbers
- Binary numbers
- String


With the following data types/data groups, only tags of the same type can be compared:
- TIME, LTIME
- Date and time
- PLC data types
- ARRAY
- STRUCT
- Tag to which ANY is pointing
- Tag to which VARIANT is pointing
  The comparison of STRINGs takes place according to the character encoding in the character
  set that is set in Windows. The comparison of WSTRINGs takes place according to the
  character encoding in UTF-16. The length of the tags and the numerical value of each
  character are used for the comparison.
  S5TIME tags are not permitted as comparison operands. An explicit conversion from S5TIME
  to TIME or LTIME is necessary.

Comparison of floating-point numbers
When floating-point numbers are compared, the operands to be compared must have the same
data type regardless of the setting for the IEC Check.
The special bit patterns of invalid floating-point numbers (NaN) that are the outcome of
undefined results (e.g. root of -1) are not comparable. This means if one of the operands has the
value NaN, the comparison expression "==: Equal" as well as "<>: Not equal" has the result
FALSE.

Comparison of character strings
The individual characters are compared by means of their code (for example, 'a' is greater than
'A') during the comparison of the strings. The comparison is performed from left to right. The
first character to be different decides the result of the comparison.
The following table shows examples of "==" comparison of strings:


<Operand1>

<Operand2>

RLO of the instruction

'AA'

'AA'


'Hello World'

'HelloWorld'


'AA'

'aa'


'aa'

'aaa'


The following table shows examples of "<>" comparison of strings:
<Operand1>

<Operand2>

RLO of the instruction

'AA'

'aa'


'Hello World'

'HelloWorld'


'AA'

'AA'


'aa'

'aaa'


You can also compare individual characters of a string. The number of the character to be
compared is specified in square brackets next to the operand name. "MyString[2]", for example,
compares the second character of the "MyString" string.

Comparison of timers, date and time
Bit patterns of invalid timers, date and times, e.g. DT#2015-13-33-25:62:99.999_999_999,
cannot be compared. This means that if one of the two operands has an invalid value, the
instructions return the following results:
"==: Equal" has the result FALSE.
"<>: Not equal" has the result TRUE.
Not all times can be compared directly with each other, such as S5TIME. In this case they are
implicitly converted into another time so that they can be compared, for example to TIME.
If you want to compare dates and times of different data types, the value of the smaller date or
time data type is implicitly converted into the larger date or time data type. This means the two
date and time data types DATE and DTL, for example, are compared on the basis of DTL.
When the implicit conversions fail, the comparison result is FALSE.

Comparing tags of WORD data type to tags of the S5TIME data type
Both tags are converted to the TIME data type when comparing a tag of WORD data type to a tag
of S5TIME data type. The WORD tag is interpreted as an S5TIME value. If one of the two tags
cannot be converted, the comparison is not performed and the result is FALSE. If the conversion
is successful the comparison is performed based on the selected comparison instruction.

Comparison of structures
Note
Availability of comparison of structures


The option to compare structures is available for a CPU of the S7-1200 series as of
firmware version >= 4.2, and for a CPU of the S7-1500 series as of firmware version
>= 2.0.
You can compare the values of two structured operands with each other when both tags are of
the same structure data type. When structures are compared, the operands to be compared
must have the same data type regardless of the setting for the IEC Check. An exception are the
comparisons in which one of the operands is a VARIANT or an ANY. If the data type is not yet
known at the time when the program is created, you can use the VARIANT data type. In this case
you can also compare the operands with a structured tag of any data type. You can also
compare two tags of the data type VARIANT or ANY with each other.
You can select the data type VARIANT for the comparison of structures from the drop-down list
in the instruction box. Tags from the following data types are possible:
PLC data type (UDT)
STRUCT (either the structure of the STRUCT data type must be contained in a PLC data type
or the two structures to be compared must be two elements of an ARRAY of STRUCT.
Instance data blocks and tags of anonymous structures are not permitted.)
Tag to which ANY is pointing
Tag to which VARIANT is pointing
The following requirements must be met so that the two tags of the data type ARRAY can be
compared with each other:
The elements must each have the same data type.
The two ARRAYs must have the same dimension.
All dimensions must have the same number of elements. The exact ARRAY limits do not have
to match.
Make sure that ARRAYs declared in the block interface in the TEMP sections are initialized
with valid values before comparing them. If an ARRAY element takes on an invalid value, the
comparison may give a wrong result.

Note
ARRAY of BOOL
When you compare two operands of the data type ARRAY of BOOL with each other
and the number of elements cannot be divided by 8, the fill bits are compared as
well. This may have an effect on the comparison result.
The table below shows an example of a comparison of structures for "==: Equal":
<Operand1>

<Operand2>

RLO of the
instruction


Tag of data type A <PLC data

Tag

Tag of data type A <PLC data

Tag

type>

value

type>

value

BOOL

FALSE

BOOL

FALSE

INT


INT


<Operand1>

<Operand2>


RLO of the
instruction

Tag of data type A

Tag value

<PLC data type>

Tag of data type

Tag value


B <PLC data
type>

BOOL

FALSE

BOOL

TRUE

INT


INT


<Operand1>

<Operand2>

RLO of the
instruction

Tag of data type A

Tag value

<PLC data type>

VARIANT

Tag value


(supplied with
tag of data type
A)

BOOL

FALSE

BOOL

FALSE

INT


INT


The table below shows an example of a comparison of structures for "<>: Not equal":
<Operand1>

<Operand2>

RLO of the
instruction


Tag of data type A <PLC data

Tag

Tag of data type A <PLC data

Tag

type>

value

type>

value

BOOL

FALSE

BOOL

FALSE

INT


INT


<Operand1>

<Operand2>


RLO of the
instruction

Tag of data type A

Tag value

<PLC data type>

Tag of data type

Tag value


B <PLC data
type>

BOOL

FALSE

BOOL

TRUE

INT


INT


<Operand1>

<Operand2>

RLO of the
instruction

Tag of data type A

Tag value

<PLC data type>

VARIANT

Tag value


(supplied with
tag of data type
A)

BOOL

FALSE

BOOL

FALSE

INT


INT


Data types of relational expressions
The following table shows the data types/data type groups you can use in relational expressions:
Operation

Operator

1st operand

2nd operand

Result

Compare for

=, <>

Integer/floating-

Integer/floating-

BOOL

point number

point number

Bit strings

Bit strings

equal, not
equal


BOOL


Compare for

=,

equal, not equal

<>

String

String

BOOL

TIME, LTIME

TIME, LTIME

BOOL

Date and time

Date and time

BOOL

VARIANT/ANY

VARIANT/ANY

BOOL

Any data type (but must

VARIANT/ANY

BOOL

VARIANT/ANY

Any data type

BOOL

PLC data type

PLC data type

BOOL

ARRAY of <data type>

ARRAY of <data type>

BOOL

with fixed and variable

with fixed and

ARRAY limits

variable ARRAY limits

STRUCT

STRUCT

BOOL
BOOL

correspond to the data
type with which the
VARIANT is supplied)

Compare for less

<,

Integer/floating-point

Integer/floating-point

than, less than-

<=,

number

number

equal to, greater

>,

than, greater than

>=

Bit strings

Bit strings

(S7-1200/1500 only)

(S7-1200/1500 only)

String

String

BOOL

TIME, LTIME

TIME, LTIME

BOOL

Date and time

Date and time

BOOL

or equal to

BOOL

Example
The following example shows a relational expression:


```scl
IF a > b THEN c:= a;


IF A > 20 AND B < 20 THEN C:= TRUE;
IF A<>(B AND C) THEN C:= FALSE;
```

Note
The comparison for STRING and DT are executed internally in the S7-300/400 by
extended instructions. The following operands are not permitted for these
functions:
Parameter of a FC
In-out parameter of an FB of type STRUCT or ARRAY

Note
Comparing the hardware data types HW_IO and HW_DEVICE
If you want to compare the two data types, you must first create a tag of data type
HW_ANY in the "Temp" section of the block interface and then copy the LADDR (of
data type HW_DEVICE) to the tag. It is then possible to compare HW_ANY and
HW_IO.
See also
Expressions
Operators and operator precedence
Overview of the valid data types


### 1.1.5 Logical expressions


Description
Logical expressions combine two operands with logical operators AND OR XOR or negating
operands NOT.
Logical operators can process the data types that are allowed in the CPU in use. The result of a
logical expression is of BOOL data type, if both operands are of BOOL data type. If at least one of
both operands is a bit string, then the result is also a bit string and is determined by the type of
the highest operand. For example, when you link a BYTE type operand to a WORD type operand,
the result is type WORD.
To link a BOOL type operand with a bit string, you must first explicitly convert it to a bit string.

Data types of logical expressions
The following table shows the data types you can use in logical expressions:


Operation

Operator

1st operand

2nd operand

Result

Negation

NOT

BOOL

-

BOOL

Bit string

-

Bit string

BOOL

BOOL

BOOL

Bit string

Bit string

Bit string

BOOL

BOOL

BOOL

Bit string

Bit string

Bit string

BOOL

BOOL

BOOL

Bit string

Bit string

Bit string

(generate
one's
complement)
AND logic

AND or &

operation

OR logic

OR

operation

EXCLUSIVE OR

XOR

logic operation

Example
The following example shows a logical expression:


```scl
IF "MyTag1" AND NOT "MyTag2" THEN c := a;
MyTag := ALPHA OR BETA;
```

See also
Expressions
Operators and operator precedence
Overview of the valid data types
SCL programming examples


### 1.1.6 Operators and operator precedence


Operators and their order of evaluation
Expressions can be linked together or nested within each other by operators.
The order of evaluation for expressions depends on the precedence of operators and brackets.
The following basic rules apply:


Arithmetic operators are evaluated before relational operators and relational operators are
evaluated before logical operators.
Operators with no precedence are evaluated according to their occurrence from left to right.
Value assignments are evaluated from right to left.
Operations in brackets are evaluated first.
The following table provides an overview of the operators and their precedence:
Operator

Operation

Precedence

+

Unary plus


-

Unary minus


**

Power


*

Multiplication


/

Division


MOD

Modulo function


+

Addition


-

Subtraction


+=, -=, *=, /=

Combined value assignments


<

Less than


>

Greater than


<=

Less than or equal


>=

Greater than or equal


Arithmetic expressions

Relational expressions


=

Equal


<>

Not equal


NOT

Negation


AND or &

Boolean AND


XOR

Exclusive OR


OR

Boolean OR


Logical expressions

Reference expressions
REF

Reference

^

Dereference


?=

Assignment attempt


()

Brackets


:=

Assignment


Miscellaneous operations


### 1.1.7 Value assignments


Definition
You can use a value assignment to assign the value of an expression to a tag. On the left side of
the assignment is the tag that takes the value of the expression on the right.
The name of a function can also be specified as an expression. The function is called by the
value assignment and returns its function value to the tag on the left.
The data type of value assignment is defined by the data type of the tag on the left. The data
type of the expression on the right must match this type.
You have the following options for programming value assignments:
Single value assignments
In case of single value assignments, an expression or tag is assigned to a single tag only:


Example: a := b;
Multiple value assignments
In case of multiple value assignments, multiple assignments can be executed with one
instruction.
Example: a := b := c;
This corresponds to the following notation:
b := c;
a := b;
Combined value assignments
In case of combined value assignments, you can combine the operators "+", "-", "*" and "/"
with the assignment operator:
Example: a += b;
This corresponds to the following notation:
a := a + b;
You can also assign combined value assignments multiple times:
a += b += c *= d;
This corresponds to the following sequence of assignments:
c := c * d;
b := b + c;
a := a + b;

Value assignments for STRUCT data type or PLC data types
An entire structure can be assigned to another if the structures are identically organized and the
data types as well as the names of the structural components match.
You can assign a tag, an expression or another structural element to an individual structural
element.

Value assignments for the ARRAY data type
An entire ARRAY can be assigned to another ARRAY if both the data types of the ARRAY elements
as well as the ARRAY limits match.
You can assign a tag, an expression or another ARRAY element to an individual ARRAY element.

Value assignments for the STRING data type
An entire STRING can be assigned to another STRING.
You can assign another STRING element to an individual STRING element.


Value assignment for data type WSTRING (S7-1200/1500)
An entire WSTRING can be assigned to another WSTRING.
You can assign another WSTRING element to an individual WSTRING element.

Value assignments for the ANY data type
You can assign a tag with the ANY data type only to the following objects:
Input parameters or temporary local data of FBs that also have the data type ANY.
Temporary local data of FCs that also have the data type ANY.
Note that you can only point to memory areas with "standard" access mode with the ANY
pointer.

Value assignments for the POINTER data type
You cannot use POINTER in value assignments in SCL.

Value assignments for the REF_TO data type
References can be assigned to each other like normal tags. The address of the referenced tag is
assigned, not its value. References can only be assigned to each other if they refer to the same
data type. No implicit data type conversion is made.
References to PLC data types, too, must be of the same data type. It is not enough for both PLC
data types to have the same structure.
References to technology objects must point to a technology object of the same type or a
derived type.
You can also assign a reference to a VARIANT. In this case the VARIANT must be declared as a
temporary tag (Temp).

Examples
The following table shows examples of single value assignments:


```scl
"MyTag1" := "MyTag2";

(* Assignment of a tag*)

"MyTag1" := "MyTag2" * "MyTag3"; (* Assignment of an
expression*)
"MyTag" := "MyFC"();

(* Call for a function that
assigns its function value
to the "MyTag" tag*)


#MyStruct.MyStructElement :=

(* Assignment of a tag to a

"MyTag";

structure element*)

#MyArray[2] := "MyTag";

(* Assignment of a tag to an
ARRAY element*)

"MyTag" := #MyArray[1,4];

(* Assignment of an ARRAY
element to a tag*)

#MyString[2] :=

(* Assignment of a STRING

#MyOtherString[5];

element to another STRING
element*)

The following table shows examples of multiple value assignments:

SCL
"MyTag1" := "MyTag2" :=

(* Assignment of a tag*)

"MyTag3";
"MyTag1" := "MyTag2" :=

(* Assignment of an

"MyTag3" * "MyTag4";

expression*)

"MyTag1" := "MyTag2" :=

(* Call of a function that

"MyTag3 := "MyFC"();

assigns its function value to
the tags "MyTag1", "MyTag1"
and "MyTag1" *)

#MyStruct.MyStructElement1 :=

(* Assignment of a tag to two

#MyStruct.MyStructElement2 :=

structure elements*)

"MyTag";
#MyArray[2] := #MyArray[32] := (* Assignment of a tag to two
"MyTag";

ARRAY elements*)

"MyTag1" := "MyTag2" :=

(* Assignment of an ARRAY

#MyArray[1,4];

element to two tags*)

#MyString[2] := #MyString[3]:= (* Assignment of a STRING
#MyOtherString[5];

element to two STRING
elements*)

The following table shows examples of combined value assignments:

SCL


"MyTag1" += "MyTag2";

(* "MyTag1" and "MyTag2" are
added and the result of the
addition is assigned to
"MyTag1".*)

"MyTag1" -= "MyTag2" +=

(* "MyTag2" and "MyTag3" are

"MyTag3";

added. The result of the
addition is assigned to
""MyTag2"" and then subtracted
from "MyTag1". The result is
assigned to "MyTag1".*)

#MyArray[2] += #MyArray[32] (* The ARRAY element
+= "MyTag";

"MyArray[32]" is added to
"MyTag". The result is assigned
to "MyArray[32]". The two ARRAY
elements are then added and the
result is assigned to the ARRAY
element "MyArray[2]". The data
types must be compatible for
this operation.*)

#MyStruct.MyStructElement1

(* The structure element

/=

"MyStructElement2" is multiplied

#MyStruct.MyStructElement2

by "MyTag". The result is

*= "MyTag";

assigned to "MyStructElement2".
The structure element
"MyStructElement1" is then
divided by "MyStructElement2"
and the result is assigned to
"MyStructElement1". The data
types must be compatible for
this operation.*)

```

See also
Operators and operator precedence
Overview of the valid data types
Addressing operands


### 1.1.8 Calculating with floating-point numbers (REAL and LREAL) in SCL


Representation of the accuracy of floating-point numbers


The data type REAL, for example, is specified and calculated in the program with an accuracy of
6 decimal places. For the calculation of floating-point numbers (REAL and LREAL), it should be
noted that this accuracy applies in general to each individual step of the calculation.
The exponents are adjusted when floating-point numbers are added and subtracted. The base
and the exponents are thus equal during the addition and subtraction and only the mantissas
are added. For additional information on the structure of floating-point numbers, refer to "See
also".

Programming example
In the following programming example, you are to perform a calculation in which two operands
of the data type REAL are to be added and one is to be subtracted. In the next step of the
calculation, the constant 1 is divided by the previous result. To do this, create a global data block
in which you declare your operands and a function in which you program the calculation
operations.

Calculation formulas
y = a + b - c
Z = 1/y
The operands are stored with the following values:
Operand

Value

REAL value

a

100 000 000

1.000000*108

b


1.000000*100

c

100 000 000

1.000000*108

Procedure
Create the data block "DB_GlobalData":
1. Double-click the "Add new block" command.
   The "Add new block" dialog box opens.
2. Click the "Data block (DB)" button.
3. Specify the name "DB_GlobalData".
4. Select "Global DB" as the type of the data block.
5. Click "OK".
6. Create the following tags in the data block and enter the corresponding start values:


The start value of both tags is 100000000.0 and is converted into 1.0E+8 according to the
data type REAL.
Create an SCL function and name it "FC_Calculate".
1. Declare the block interface as follows:

2. Write the following formulas in your program code and establish an online connection to
   see the result:


```scl
#y := "DB_GlobalData".a + "DB_GlobalData".b "DB_GlobalData".c;
#z := 1/#y;

As you can see, the result at the operand is #y = 0, even though the number 1 is actually
expected as result.
The incorrect result comes about as follows:
```

1. In the first step of the calculation, the operands a + b are added. The REAL values of the two
   operands (a = 1.000000*108 and b = 1.000000*100) look as follows after the exponents have
   been adjusted:


a = 1.000000*108 and b = 0.00000001*108. The last two places of the second number
(operand b) are truncated, as they can no longer be represented due to the accuracy of 6
decimal places. Therefore, a 0 instead of a 1 is added to the operand.
2. In the second calculation step, the operand C is subtracted from the result of the preceding
   calculation step (intermediate result = 1.000000*108 - c = 1.000000*108 is 0.000000e0).
3. If you now calculate the operand z in the next calculation step, you try to divide by zero.

1. Possible solution
   To work around such cases, you can simply adjust your calculation formula. Write the formula as
   follows instead:

Calculation formulas
y = a - c + b
Z = 1/y
Since the result 0.000000e0 is available in this case after the first calculation step (operand a c), the addition of the REAL number in the second calculation step (intermediate result + b)
leads to the correct result (y = 0.000000*10​0·+ 1.000000*100 = 1.000000*100).

We recommend that you check how the calculation can be made most effectively before you
program a calculation.

2. Possible solution
   To calculate the above named formulas, use the LREAL data type instead of the REAL data type.
   Since the data type is processed with an accuracy of 15 decimal places, this problem does not
   even arise.
1. In the global data block "DB_GlobalData", create three new tags with the same values, each
   with the data type LREAL.


2. In the block interface of the FC "FC_Calculate", also declare two new tags with the data type
LREAL.

3. Use the new LREAL tags for the formulas in your program code and establish an online
   connection to see the result.


```scl
#y_LREAL := "DB_GlobalData".a_LREAL + "DB_GlobalData".b_LREAL
- "DB_GlobalData".c_LREAL;
#z_LREAL := 1/#y_LREAL;

```

See also
REAL
LREAL (S7-1200, S7-1500, S7-1200 G2)
Invalid floating-point numbers


### 1.1.9 Calculating with constants in SCL


Interpretation of typed and non-typed constants
Constants are data with a fixed value that cannot change during program runtime. Constants
can be read by various program elements during the execution of the program but cannot be
overwritten. There are defined notations for the value of a constant, depending on the data type
and data format. A distinction is made between the typed and non-typed notation.
We recommend that you do not mix typed and non-typed constants within mathematical
functions as you may otherwise be faced with unwanted implicit conversions and thus end up
with incorrect values.

Programming example
In the following programming example, you see a calculation operation with a typed and a nontyped constant.
1. Create an SCL function block and name it "FB_MathsFunctions".
2. Declare the "Variable_DINT" tag in the "Temp" section of the block interface.

3. Write the following program code:
   Variable_DINT := INT#1 +50000;
   In this math operation, the typed constant INT#1 and the non-typed constant 50000 are to
   be added. The non-typed constant 50000 is underlined in yellow in the software to indicate
   that the constant value is outside the permitted range of the data type INT.

To see the result, go online.
1. Compile the SCL function block "FB_MathsFunctions" by right-clicking the command
   "Compile > Software (only changes)" to execute it.
2. Download the block with the command "Download to device > Software (only changes)".
3. Go online and monitor your block.


The data type of the typed constant defines the data type of the addition. This means that
the addition is performed in the data type area INT. In the first step, the non-typed constant
50000 is implicitly converted into the data type INT. However, the conversion leads to a
negative value (-15536). This value is then added to the typed constant (INT#1). The result is
-15535. Since the tag to which the result of the addition is to be written is declared with the
data type DINT, the number -15535 is implicitly converted into the data type DINT and
written to the tag "Variable_DINT". However, the result remains negative.

1. Possible solution
   One option for avoiding this undesired result is to type both constants. If you type both
   constants, the longer data type determines the calculation operation.
1. Write the following program code in the "FB_MathsFunctions" SCL function block:

In this calculation operation, the typed constant INT#1 and the typed constant DINT#50000
are to be added.
To see the result, go online.
1. Compile the SCL function block "FB_MathsFunctions" by right-clicking the command
   "Compile > Software (only changes)" to execute it.
2. Download the block with the command "Download to device > Software (only changes)".
3. Go online and monitor your block.

The constant INT#1 is converted into the DINT data type and the addition of the two
constants is executed in the DINT data type area.

2. Possible solution
   Another option for avoiding this undesired result is not to type both constants. If you do not
   type both constants, these are then interpreted as the widest possible data type on the current
   CPU. This means that on an S7-1500 series CPU, the two constants are interpreted as LINT data
   type.
1. Write the following program code in the "FB_MathsFunctions" SCL function block:

In this calculation operation, the non-typed constant 1 and the non-typed constant 50000
are to be added.
To see the result, go online.


1. Compile the SCL function block "FB_MathsFunctions" by right-clicking the command
"Compile > Software (only changes)" to execute it.
2. Download the block with the command "Download to device > Software (only changes)".
3. Go online and monitor your block.

The constants 1 and 50000 are interpreted as LINT data type and the result of the addition is
again converted into the DINT data type.
See also
Basics of constants
Overview of the valid data types


## 1.2 Settings for SCL


### 1.2.1 Overview of the settings for SCL


Overview
The following tables show the settings you can make for SCL:

Editor settings
Group

Setting

Description

View

Operand representation

Representation of the operand in the
program editor. You can select between the
following options:
Symbolic and absolute
Symbolic

Tag information

Additional information for the tags used is
displayed in the program editor. When you
select the option "Tag information with
hierarchical comments", the comments of
the higher structure levels are also displayed
for structured tags.

Keyword highlighting

Notation used to represent the keywords of
the programming language. You can choose
between uppercase and lowercase letters or
a notation corresponding to the


conventions of the Pascal programming language.
Left-align actual

Left-aligns the actual parameters for a block call. Only has this effect

parameters

when the "Smart" option is selected in the settings under "General >
Script/text editors > Indent".

Default settings for new blocks
If you create new blocks, the following settings are set as default values. You can change these
in the block properties at a later point in time.
Group

Setting

Description

Compile

Create extended status

Allows all tags in a block to be monitored.

information

The memory requirements of the program
and execution times increase, however,
with this option.

Check ARRAY limits1)

Checks at runtime whether array indices are
within the declared range for an ARRAY. If
an array index exceeds the permissible
range, the enable output ENO of the block
is set to "0".

Set ENO automatically

Checks at runtime whether errors occur in
the processing of certain instructions. If a
runtime error occurs, the enable output
ENO of the block is set to "0".

Block

View

interface

Defines whether the block interface of
newly created blocks is shown in the table
view or the text view.

1)For CPUs of the S7-300/400 series: When the ARRAY limits are violated, the enable

output ENO is set to FALSE.
For CPUs of the S7-1200/1500 series: When the ARRAY limits are violated, the enable
output ENO is not set to FALSE. See "Addressing ARRAY components" for error query
options.
See also
Changing the settings
EN/ENO mechanism


### 1.2.2 Changing the settings


Procedure
To change the settings, follow these steps:
1. Select the "Settings" command in the "Options" menu.
   The "Settings" window is displayed in the work area.
2. In the area navigation, select the "PLC programming" group.
3. Change the settings.

Result
The change will be loaded directly, there is no need to save it explicitly.
See also
Overview of the settings for SCL


## 1.3 The programming window of SCL


### 1.3.1 Overview of the programming window


Function
The programming window is the work area, where you enter the SCL program.
The following figure shows the programming window of SCL:

The programming window consists of the following sections:
Section


Meaning


① Sidebar

You can set bookmarks and breakpoints in the sidebar.

② Line numbers

The line numbers are displayed to the left of the program
code.

③ Outline view

The outline view highlights related code sections.

④ Code area

You edit the SCL program in the code area.

⑤ Display of the absolute

This table shows the assignment of symbolic operands to

operands

absolute addresses.

See also
Customizing the programming window
Formatting SCL code
Expanding and collapsing sections of code
Navigate to definitions
Using bookmarks


### 1.3.2 Customizing the programming window


Introduction
You can customize the appearance of the programming window and the program code in the
following way:
By setting the font, size and color
By setting the tab spacing
By displaying the line numbers
By showing or hiding the absolute operands

Setting the font, size and color
To set the font, size and color, follow these steps:
1. Select the "Settings" command in the "Options" menu.
   The "Settings" window is displayed in the work area.
2. Select the "General > Script/text editors" group.
3. Select the desired font and font size or choose a font color for the individual language
   elements.

Setting the tab spacing


To provide a better overview of the program, lines are indented according to syntax. Define the
depth of indentation with the tab spacing.
To set the tab spacing, follow these steps:
1. Select the "Settings" command in the "Options" menu.
   The "Settings" window is displayed in the work area.
2. Select the "General > Script/text editors" group.
3. Set the tab spacing.

Show line numbers
To display the line numbers, follow these steps:
1. Select the "Settings" command in the "Options" menu.
   The "Settings" window is displayed in the work area.
2. Select the "General > Script/text editors" group.
3. Select the "Show line numbers" option.

Show or hide the absolute operands
You can show the assignment of symbolic and absolute operands in a table next to the program
code, if required.
To hide or show the display of the absolute operands, follow these steps:
1. Click the "Absolute/symbolic operands" icon in the toolbar.
   The display of the absolute operands appears.
2. To move the display, click the table and drag it to the desired position while holding down
   the mouse button.
3. To change the width of the table, click on the right or left table border and drag it to the
   right or left while holding down the mouse button.
   See also
   Overview of the programming window
   Formatting SCL code
   Expanding and collapsing sections of code
   Navigate to definitions
   Using bookmarks


### 1.3.3 Formatting SCL code


Introduction
To make the program clearer, you can indent or outdent individual lines manually or format
code sections. Note the following information about formatting code sections:


The type of formatting is based on the general settings for indents, but at least the line or
the section is always indented. If you selected the setting "Smart", unnecessary spaces within
the SCL instruction are also removed.
Only syntactically correct code sections can be formatted.
If you place the insertion point in the first or last line of an instruction for program control,
for example in an IF instruction in the line with the "IF", the entire instruction is formatted.
If you select text, only the selected text is formatted.
In addition, you can set that the actual parameters of block calls are generally to be left-aligned.
To do this, "Smart" must be selected as the option for indents.

Indenting or outdenting lines
To indent or outdent individual lines, follow these steps:
1. Click on the line you want to indent or outdent.
2. Press the "Indent text", "Outdent text" button into the toolbar of the programming editor.

Note
You can set the width of the indent in "Options > Settings".

Formatting code sections
To format code sections, follow these steps:
1. Select the text that you want to format or place the insertion point in the appropriate line.
2. Select the "Format selected text automatically" button into the toolbar of the programming
   editor.

Left-aligning actual parameters of block calls
To left-align the actual parameters of block calls, follow these steps:
1. Select the "Settings" command in the "Options" menu.
   The "Settings" window is displayed in the work area.
2. Select the "General > Script/text editors" group in the area navigation.
3. Under "Indent", select the "Smart" option.
4. Select the "PLC programming > SCL (Structured Control Language)" group in the area
   navigation.
5. Select the "Left-align actual parameters" check box under "View".
   The actual parameters are left-aligned for newly inserted block. To left-align the actual
   parameters of existing block calls, you can select the block calls and click the "Automatically
   format selected text" button in the toolbar of the program editor.


See also
Overview of the programming window
Customizing the programming window
Expanding and collapsing sections of code
Overview of the script and text editor settings
Navigate to definitions
Using bookmarks


### 1.3.4 Expanding and collapsing sections of code


Introduction
SCL instructions can span several lines. Examples for this are program control instructions or
block calls.
Such instructions that belong together are identified as follows:
An outline view between the display line number and the program code marks the entire
code section.
When you select the opening keyword, the closing keyword is automatically highlighted.
To improve clarity, you can expand or collapse sections of code that belong together in the
outline display. The selected outline display is retained when you close the block or the project
so that, the next time you open the block, the sections of code are displayed in exactly the same
way as they were when you closed it.

Procedure
To expand or collapse the code section, follow these steps:
1. Click the minus sign in the outline view.
   The code section closes.
2. Click the plus sign in the outline view.
   The code section opens.
   See also
   Overview of the programming window
   Customizing the programming window
   Formatting SCL code
   Navigate to definitions
   Using bookmarks


### 1.3.5 Navigate to definitions

You can use elements in your program code that were defined in other editors, for example, tags
or data blocks (DBs) of called function blocks (FBs). To view the definition instances in the
corresponding editors, you can specifically navigate to these instances.

Procedure
To navigate to the definition of a code element, follow these steps:
1. Right-click on the code element.
2. Select the "Go to > Definition" command in the shortcut menu.
   The editor in which the code element was defined opens and the definition instance is
   displayed.
   Or:
1. Press and hold down the <Ctrl> key.
2. Move the mouse pointer over your program code.
   If the mouse pointer moves across a code element whose definition can be displayed, it is
   shown as underlined and the name of the element turns into a link.
3. Click on the link.
   The editor in which the code element was defined opens and the definition instance is
   displayed.
   See also
   Overview of the programming window
   Customizing the programming window
   Formatting SCL code
   Expanding and collapsing sections of code
   Using bookmarks


### 1.3.6 Using bookmarks


#### 1.3.6.1 Basics of bookmarks


Function
You can use bookmarks to mark program locations in extensive programs so that you can find
them quickly later if they need revising. Bookmarks are displayed in the sidebar of the
programming window. You can navigate between multiple bookmarks within a block using
menu commands.
Bookmarks are saved with the project and are therefore available for anyone who wants to edit
the block. However, they are not loaded to a device.
Bookmarks are not evaluated when blocks are compared.


See also
Setting bookmarks
Navigating between bookmarks
Deleting bookmarks


#### 1.3.6.2 Setting bookmarks


Requirement
The SCL block is open.

Procedure
To set a bookmark, follow these steps:
1. Right-click on the desired line in the sidebar.
2. Select the "Bookmarks > Set" command in the shortcut menu.
   Or:
1. Click on the line in which you want to place the bookmark.
2. Click the "Set/delete bookmark" button in the toolbar.
   Or:
1. Hold down the <Ctrl> key.
2. Click on the line in the sidebar in which you want to place the bookmark.

Result
A bookmark is placed in the program code.
See also
Basics of bookmarks
Navigating between bookmarks
Deleting bookmarks


#### 1.3.6.3 Navigating between bookmarks


Requirement
Several bookmarks are set in a block.

Procedure
To navigate between bookmarks, follow these steps:
1. Set the insertion cursor in the program code.


2. In the "Edit" menu, select the "Go to > Next bookmark" or "Go to > Previous bookmark"
command.
Or:
1. Set the insertion cursor in the program code.
2. In the toolbar of the programming editor, click the "Go to next bookmark", "Go to previous
   bookmark" button.
   Or:
1. Click in the sidebar.
2. Select the "Bookmarks > Next" or "Bookmarks > Previous" command in the shortcut menu.

Result
The line with the bookmark is highlighted.
See also
Basics of bookmarks
Setting bookmarks
Deleting bookmarks


#### 1.3.6.4 Deleting bookmarks

You can delete individual bookmarks or all bookmarks from the block or the CPU.

Deleting individual bookmarks
To delete an individual bookmark, follow these steps:
1. Right-click in the sidebar on the line in which you want to delete the bookmark.
2. Select the "Bookmarks > Remove" command in the shortcut menu.
   Or:
1. Click on the line in which you want to delete the bookmark.
2. In the "Edit" menu, select the "Bookmarks > Remove" command.
   Or:
1. Click on the line in which you want to delete the bookmark.
2. Click the "Set/delete bookmark" button in the toolbar.

Deleting all bookmarks from the block
To delete all bookmarks from the block, follow these steps:
1. Right-click in the sidebar.
2. Select the "Bookmarks > Delete all from block" command in the shortcut menu.


Or:
1. In the "Edit" menu, select the "Bookmarks > Delete all from block" command.
   See also
   Basics of bookmarks
   Setting bookmarks
   Navigating between bookmarks


## 1.4 Entering SCL instructions


### 1.4.1 Rules for SCL instructions


Instructions in SCL
SCL recognizes the following types of instructions:
Value assignments
Value assignments are used to assign a tag a constant value, the result of an expression or
the value of another tag.
Instructions for program control
Instructions for program control are used to implement program branches, loops or jumps.
Additional instructions from the "Instructions" task card
The "Instructions" task card offers a wide selection of standard instructions that you can use
in your SCL program.
Block calls
Block calls are used to call up subroutines that have been placed in other blocks and to
further process their results.

Rules
You need to observe the following rules when entering SCL instructions:
Instructions can span several lines.
Each instruction ends with a semicolon (;).
No distinction is made between upper and lower case.
Comments serve only for documentation of the program. They do not affect the program
execution.

Examples
The following examples shows the various types of instructions:


```scl


// Example of a value assignment
"MyTag":= 0;
// Example of a block call
"MyDB"();
// Example of a program control instruction
WHILE "Counter" < 10 DO
"MyTAG" := "MyTag" + 2;
END_WHILE;
```

See also
Basics of SCL


### 1.4.2 Entering SCL instructions manually


Requirement
An SCL block is open.

Procedure
To enter SCL instructions, follow these steps:
1. Enter the syntax of the instruction using the keyboard.
   You are supported by the auto-complete function when performing this task. It offers all the
   instructions and operands that are allowed at the current location.
2. Select the required instruction or the desired operand from the auto-complete function.
   If you select an instruction that requires specification of operands, placeholders for the
   operands are inserted into the program. The placeholders for the operands are highlighted
   in yellow. The first placeholder is selected.
3. Replace this placeholder with an operand.
4. Use the <TAB> key to navigate to all other placeholders and replace them with operands.

Note
You can also drag-and-drop a defined operand from the PLC tag table or from the
block interface into the program. To replace an operand that has already been
inserted, hover the mouse pointer briefly over the operand to be replaced before
releasing the mouse button. This selects the operand and when you release the
mouse button it is replaced by the new operand.


Result
The instruction is inserted.
The programming editor performs a syntax check. Incorrect entries are displayed in red and
italics. In addition, you also receive a detailed error message in the inspector window.
See also
Using autocompletion in textual programming languages
Expanding and reducing the parameter list
Surround program code with structure elements
Data type conversion for S7-1200 (S7-1200)


### 1.4.3 Inserting SCL instructions using the 'Instructions' task card

The "Instructions" task card offers a wide selection of instructions that you can use in your SCL
program. The SCL-specific instructions for program control are available in the "Instructions" task
card.

Requirement
An SCL block is open.

Procedure
To insert SCL instructions into a program using the "Instructions" task card, follow these steps:
1. Open the "Instructions" task card.
2. To insert the instruction, select one of the following steps:
   Navigate to the SCL instruction you want to insert and drag-and-drop it to the required
   line in the program code. The insertion location is highlighted by a green rectangle.
   Select the location in the program code where you want to insert the instruction and then
   double-click on the instruction you want to insert.
   The instruction is inserted in the program. The placeholders for the operands are highlighted
   in yellow. A light yellow indicates the optional parameters that you do not necessarily have
   to interconnect. A darker yellow indicates the mandatory parameters that you must
   interconnect. The first placeholder is selected.
3. Replace this placeholder with an operand. You can also drag a tag from the interface or the
   PLC tag table with drag-and-drop to the placeholder.
4. Use the <TAB> key to navigate to all other placeholders and replace them with operands.

Result
The instruction is inserted.


The programming editor performs a syntax check. Incorrect entries are displayed in red and
italics. In addition, you also receive a detailed error message in the inspector window.
See also
Using autocompletion in textual programming languages
Expanding and reducing the parameter list
Surround program code with structure elements
Data type conversion for S7-1200 (S7-1200)


### 1.4.4 Surround program code with structure elements

You have the option of surrounding your program code with the following structure elements:
Ranges
- REGION
  Control structures
- IF ... THEN
- CASE ... OF ...
- FOR ... TO ... DO ...
- WHILE ... DO ...
  Comment section
- /**/

Procedure
To surround your program code with a structure element, proceed as follows:
1. Select the program code that you want to surround with a structure element.
2. Right-click the selected program code.
3. Select the required structure element under "Surround with" in the shortcut menu.
4. Alternatively, you can also select the structure element in the favorites or in the
   "Instructions" task card in the "Simple instruction > Program control" pane.
   See also
   Entering SCL instructions manually
   Inserting SCL instructions using the "Instructions" task card
   Inserting comments


### 1.4.5 Working with regions


#### 1.4.5.1 Using regions


Function
In SCL, you can structure your program code in regions. This improves the clarity of your
program because you combine related parts of the program and can expand and collapse
regions as needed. A region overview is available for fast navigation in the regions. The region
overview appears next to the program window and can be displayed or hidden as needed.
The following figure shows the region overview and the programming window:

The region overview also shows the regions in which there are syntax errors. This allows you to
quickly navigate to faulty code positions and rectify errors.
To summarize a program part in a region, enclose it with the keywords "REGION" and
"END_REGION". Depending on your settings in the keyword highlighting, the notation of the
keywords can also be "region" and "end_region" or "Region" and "End_Region". The keywords are
automatically converted to the notation that corresponds to the current setting. To find
"REGION" and "END_REGION" keywords that belong together, click either "REGION" or
"END_REGION". Both keywords are highlighted in color as a result.
You can give each region a name. This has the following advantages:
The name is also visible when a region is collapsed. This allows you to keep an overview of
your program code.
You can identify the regions in the region overview more easily and navigate to specific
regions.
If you insert the name as a multilingual comment, you can translate the name in other
project languages. To do so, surround the name with the character strings "(/* " and "*/)".
However, you can only insert the name as a non-translatable name or as a multilingual
comment. Note the following:
- The mixing of normal names and names as multilingual comments is not permitted.


- The name as a multilingual comment cannot extend over several lines.
- You can also copy regions if they have a multilingual comment as a name. If translations
  already exist for this, they are also adopted for the copy of the region. If you then change
  the name of the region, it will be changed in the current editing language.
  See also: Working with multilingual projects
  Specifying a name is optional.

Syntax
Use the following syntax to combine the program parts into regions:

REGION <Name> or (/*<Name as a multilingual comment>*/)
<Instructions>
END_REGION
Note the following information when using regions:
The keywords "REGION" and "END_REGION" must be at the start of a line. Only spaces are
allowed before the keywords.
All characters after the keyword "END_REGION" are considered to be a comments and
therefore have no effect on the execution of the program.
All instructions must be completed within a region.
Within CASE statements the instructions can be enclosed by regions. The constants which
are used for comparison of the CASE statement must be outside the regions, however. The
regions must not cover several branches.
The following example shows the permitted use of regions within a CASE statement:
CASE <Expression> OF
<Constant1> : REGION <Instructions1> END_REGION
<Constant2> : REGION <Instructions2> END_REGION
ELSE REGION <Instructions0> END_REGION
END_CASE
The following example shows non-permitted uses of regions within CASE statements:
CASE <Expression> OF
REGION <Constant1> : <Instructions1> END_REGION
<Constant2> : REGION <Instructions2> END_REGION
ELSE <Instructions0>
END_CASE


CASE <Expression> OF
<Constant1> : <Instructions1> REGION
<Constant2> : END_REGION <Instructions2>
ELSE <Instructions0>
END_CASE
In these cases, the constants within a region are interpreted as jump labels which can be
reached with GOTO, but which are not are taken into consideration by the CASE statements.
You also have the option to nest regions. However, make sure that regions within other regions
are successfully completed:

REGION <Name>
<Instructions>
REGION <Name>
<Instructions>
END_REGION
<Instructions>
REGION <Name>
REGION
<Instructions>
END_REGION
REGION <Name>
<Instructions>
END_REGION
END_REGION
END_REGION
See also
Inserting regions
Copying and inserting regions
Navigating in regions
Deleting regions


#### 1.4.5.2 Inserting regions

You have the following options to insert regions in your program code:


You can insert regions manually via the keyboard.
You can insert regions via the "Instructions" task card. You can hereby insert either empty
regions or surround existing program code with regions.
You can insert regions via the favorites You can hereby insert either empty regions or
surround existing program code with regions.

Inserting regions manually via the keyboard
To insert a region into your program code manually via the keyboard, follow these steps:
1. Place the cursor at the position where you want to insert a region.
2. Enter the keyword "REGION".

Note
Depending on your settings in the keyword highlighting, the notation of the
keywords can also be "region" and "end_region" or "Region" and "End_Region".
The keywords are automatically converted to the notation that corresponds to
the current setting.
3. Enter the name for the region either as normal or as a multilingual comment. This step is
   optional.
4. Place the cursor at the end of the region.
5. Enter the keyword "END_REGION".
   The corresponding program code is combined in a region that you can expand and collapse.
   The new region is visible in the region overview. If you have not assigned a name, it is
   indicated in the region overview with the name "Unnamed".

Inserting regions via the "Instructions" task card
To insert a region in your program code via the "Instructions" task card, proceed as follows:
1. Place the cursor at the position where you want to insert an empty region or select the
   program code which you want to surround with a region.
2. Open the "Instructions" task card.
3. Navigate to "Control Panel > REGION".
4. Drag the instruction REGION to the position in your program code at which you want to
   insert a region, or insert the instructionREGION by double-clicking.
   Either an empty region is inserted or the selected program code is surrounded with a region.
   The new region is visible in the region overview and the placeholder "_name_" is used as
   name.


5. Replace the placeholder "_name_" with the desired name either as normal text or as
multilingual comments. If you do not want to assign a name, delete the placeholders. In this
case, the new region appears in the region overview with the name "Unnamed".

Insert via the favorites
To insert a region in your program code via the favorites, proceed as follows:
1. Place the cursor at the position where you want to insert an empty region or select the
   program code which you want to surround with a region.
2. Click the "REGION" instruction in the Favorites pane or on the Favorites bar in the program
   editor.
   Either an empty region is inserted or the selected program code is surrounded with a region.
   The new region is visible in the region overview and the placeholder "_name_" is used as
   name.
3. Replace the placeholder "_name_" with the desired name either as normal text or as
   multilingual comments. If you do not want to assign a name, delete the placeholders. In this
   case, the new region appears in the region overview with the name "Unnamed".
   See also
   Using regions
   Copying and inserting regions
   Navigating in regions
   Deleting regions


#### 1.4.5.3 Copying and inserting regions

You can also copy regions and their contents and insert them back into your program code.

Procedure
To copy regions and their contents, follow these steps:
1. Open the region overview.
2. Right-click the region you want to copy and select the "Copy" command from the shortcut
   menu.
3. Place the cursor at the position in your program code at which you want to insert the region.
4. Insert the region either via the "Insert" shortcut menu command or via the key combination
   <Ctrl+V> in your program code.
   The copied region is inserted expanded together with its contents into your program code.
   In addition, the region is inserted in the region overview.
5. If necessary, assign a new name for the inserted region.
   Or:


1. Select the region in the program window. The region can be expanded or collapsed.
2. Copy the region either via the shortcut menu "Copy" or the key combination <Ctrl+C>.
3. Place the cursor at the position in your program code at which you want to insert the region.
4. Insert the region either via the "Insert" shortcut menu command or via the key combination
   <Ctrl+V> in your program code.
   The copied region is inserted expanded together with its contents into your program code.
   In addition, the region is inserted in the region overview.
5. If necessary, assign a new name for the inserted region.
   See also
   Using regions
   Inserting regions
   Navigating in regions
   Deleting regions


#### 1.4.5.4 Navigating in regions

You can use the region overview to navigate quickly in the regions. The region overview displays
all regions that exist in your program code. In addition, it offers the following functions:
Synchronizing the display of the regions in the region overview and in the programming
window:
You can specify whether expanding and collapsing regions affects only the region overview
or the programming window, or both.
Expanding and collapsing an individual region:
You can expand and collapse individual regions in either the region overview or in the
programming window. If you have switched on synchronization, the region is expanded or
collapsed in both windows.
Expanding or collapsing all regions:
You can expand or collapse all regions simultaneously either in the region overview or in the
programming window. If you have switched on synchronization, the regions are expanded or
collapsed in both windows.

Synchronizing the display of the regions in the region overview and in
the programming window
To define the synchronization of the display for the regions in the region overview and in the
programming window, proceed as follows:
1. Open the region overview.
2. To switch on the synchronization of the display, click "Synchronization on/off" on the toolbar
   in the region overview.


The button for the synchronization is displayed as active.
3. To switch off the synchronization of the display, click "Synchronization on/off" on the toolbar
   in the region overview.
   The button for the synchronization is displayed as inactive.

Expanding and collapsing an individual region
To expand or collapse an individual region, follow these steps:
1. Open the region overview.
2. In the region overview, right-click on the region that you want to expand or collapse.
3. Select the command "Expand" or "Collapse" in the shortcut menu.
   Or:
1. Open the region overview.
2. In the region overview, select the region that you want to expand or collapse.
3. Press the shortcut <Ctrl+Shift+Num+> to expand or <Ctrl+Shift+Num-> to collapse.
   Or:
1. In the programming window, place the cursor in the region that you want to expand or
   collapse.
2. Press the shortcut <Ctrl+Shift+Num+> to expand or <Ctrl+Shift+Num-> to collapse.
   Depending on the synchronization settings, the region is either expanded or collapsed in the
   region overview or in the programming window or in both windows.

Expanding or collapsing all regions:
To expand or collapse all regions simultaneously, follow these steps:
1. Open the region overview.
2. To expand all regions, click "Expand all" on the toolbar in the region overview.
3. To collapse all regions, click "Collapse all" on the toolbar in the region overview.
   Or:
1. Open the region overview.
2. Select any region in the region overview.
3. To expand all regions, press the shortcut <Ctrl+Shift+Num*>.
4. To collapse all regions, press the shortcut <Ctrl+Shift+Num/>.
   Or:
1. Place the cursor in the programming window.
2. To expand all regions, press the shortcut <Ctrl+Shift+Num*>.
3. To collapse all regions, press the shortcut <Ctrl+Shift+Num/>.


Depending on the synchronization settings, all regions are either expanded or collapsed in the
region overview or in the programming window or in both windows.
See also
Using regions
Inserting regions
Copying and inserting regions
Deleting regions


#### 1.4.5.5 Deleting regions

You can remove regions from program code at any time.

Procedure
To delete a region, proceed as follows:
1. In your program code, remove the keyword "REGION" and the name of the region if you
   have assigned a name.
2. Delete the corresponding keyword "END_REGION" in your program code.
   The region is deleted from the program code and the region overview.

Note
As soon as you have removed either the keyword "REGION" or "END_REGION"
from the program code, you can in each case recognize the respective
associated keyword by the fact that it is marked with a red line for a syntax
error.
See also
Using regions
Inserting regions
Copying and inserting regions
Navigating in regions


### 1.4.6 Defining the data type of an SCL instruction


#### 1.4.6.1 Basic information on the data types of SCL instructions


Introduction
The SCL instructions that you employ for block programming use specific data types to calculate
function values. Certain SCL instructions only support the use of a specific data type. You cannot
change the data type for these instructions. However, most of the SCL instructions support the


use of different data types. We differentiate between the following two types of such
instructions:
Instructions for which the data type of the function value is determined by the data type of
the input parameters. This is the case for most instructions.
Instructions with default data type. The instructions listed in the following table are of this
type.
You will have to change the default data type if this is incompatible with the data type of the
input parameter used. You can always change the data type based on the following syntax:
_<data type>

SCL instructions with default data type
The following table lists the SCL instructions with default data types:
Instruction

Default data type

CEIL

DINT

DECO

DWORD

FLOOR

DINT

NORM_X

REAL

PEEK

BYTE

SCALE_X

INT

TRUNC

DINT

CONCAT

STRING

T_DIFF

TIME

See also
Changing the data type of an SCL instruction
Example for changing the data type of an SCL instruction


#### 1.4.6.2 Changing the data type of an SCL instruction


Procedure


Proceed as follows to insert an SCL instruction and change its data type:
1. Insert the instruction at the required point in the program using drag-and-drop.
2. Specify the operands for the instruction.
   The data type of the function value is specified based on the input parameters, or the default
   data type of the instruction is used.
3. Append the "_<data type>" string to the instruction name.
   "<data type>" represents the data type you need for the instruction.
   See also
   Basic information on the data types of SCL instructions
   Example for changing the data type of an SCL instruction


#### 1.4.6.3 Modifying the data types of IEC timers and IEC counters

IEC timers and IEC counters are internal system function blocks and require an instance data
block. You can create the instance data blocks either as single or multi-instance. The data type
of the instance data block is determined according to the associated instruction. For CPUs of the
S7-1200 and S7-1500 series, you can, however execute the instructions with different data
types, depending on your requirements.
If the newly set data type of the instance data block does not match the data type of the input
parameter, an implicit conversion takes place if possible. If the conversion is not possible, you
will receive an error message.

Procedure
To change the data type of an IEC timer or IEC-counter instance data block, proceed as follows:
1. Open the block in which you call the IEC timer or IEC counter.
   Depending on the instance type of the instance data block, there is a green-bordered box
   before (multi-instance) or after (single instance) the name of the instance data block.
2. Click the green-bordered box.
   A drop-down list box with the valid data types for the instance data block is opened.
3. Select the desired data type.

#### 1.4.6.4 Example for changing the data type of an SCL instruction


Changing the default data type of the "Decode" instruction (DECO)
Data type DWORD is set as default if you insert the "Decode" instruction in the program.
"Tag_Result" := DECO(IN := "Tag_Value");
Modify the program code as follows to convert the data type from DWORD to BYTE:
"Tag_Result_BYTE" := DECO_BYTE(IN := "Tag_Value");


See also
Basic information on the data types of SCL instructions
Changing the data type of an SCL instruction


### 1.4.7 Displaying or hiding tag information


Introduction
Regardless of whether the operands are represented in absolute or symbolic form, you can show
and hide simple or hierarchical comments used to document global tags. This information is
taken from the PLC tag table.
You can display the tag information either for all the blocks or for individually opened blocks. If
you display the tag information for all the blocks, the tag information for all blocks currently
opened and opened in future is shown.
You can hide the tag information at any time again. If you have hidden the tag information for
all blocks, you can display it again for individual ones that you have opened.
If you select the display of tag information with hierarchical comments, the comments of the
higher structure levels of structured tags will also be displayed. The display is in brackets after
the comment of the tags; the comments of the individual levels are separated by a period. If
there is no comment at a structure level for a tag, it is omitted in the display and this is
recognizable because there are two periods.

Displaying or hiding tag information for all blocks
Follow the steps below to display or hide the tag information for all blocks:
1. Select the "Settings" command in the "Options" menu.
   The "Settings" window is displayed in the work area.
2. In the area navigation, select the "PLC programming" group.
3. If you want to show the tag information, either select the "Expand" option in the "Tag
   information" drop-down list or the "Tag information with hierarchy" depending on whether
   you want to display simple or hierarchical comments.
4. If you want to hide the tag information, select the "Collapse" option in the "Tag information"
   drop-down list.
   The tag information is displayed or hidden for all blocks. When you open further blocks, the
   tag information is displayed or hidden depending on the selected setting.

Displaying or hiding tag information for an opened block
Follow the steps below to display or hide the tag information for an opened block:


1. If you want to show the tag information, either select the "Show tag information" option in
the "Shows the tag information" drop-down list or the "Tag information with hierarchy"
depending on whether you want to display simple or hierarchical comments.
2. If you want to hide the tag information, select the "Hide tag information" option in the
   "Hides tag information" drop-down list.
   The tag information is displayed or hidden.


### 1.4.8 Using Favorites in SCL


#### 1.4.8.1 Adding SCL instructions to the Favorites


Requirement
A block is open.
The multipane mode is set for the "Instructions" task card or the Favorites are also displayed
in the editor.

Procedure
To add SCL instructions to the Favorites, follow these steps:
1. Open the "Instructions" task card.
2. Maximize the "Basic instructions" pane.
3. Navigate in the "Basic instructions" pane to the instruction that you want to add to the
   Favorites.
4. Drag-and-drop the instruction into the "Favorites" pane or into the Favorites area in the
   program editor.

Note
To additionally display the Favorites in the program editor, click the "Display
favorites in the editor" button in the program editor toolbar.
See also
Overview of the program editor
Inserting SCL instructions using Favorites
Removing SCL instructions from the Favorites


#### 1.4.8.2 Inserting SCL instructions using Favorites


Requirement
A block is open.
Favorites are available.


Procedure
To insert an instruction into a program using Favorites, follow these steps:
1. Drag-and-drop the desired instruction from Favorites to the desired position.
   Or:
1. Select the position in the program where you want to insert the instruction.
2. In the Favorites, click on the instruction you want to insert.

Note
To additionally display the Favorites in the program editor, click the "Display
favorites in the editor" button in the program editor toolbar.
See also
Overview of the program editor
Adding SCL instructions to the Favorites
Removing SCL instructions from the Favorites


#### 1.4.8.3 Removing SCL instructions from the Favorites


Requirement
A code block is open.

Procedure
To remove instructions from Favorites, follow these steps:
1. Right-click on the instruction you want to remove.
2. Select the "Remove instruction" command in the shortcut menu.

Note
To additionally display the Favorites in the program editor, click the "Display
favorites in the editor" button in the program editor toolbar.
See also
Overview of the program editor
Adding SCL instructions to the Favorites
Inserting SCL instructions using Favorites


### 1.4.9 Insert block calls in SCL


#### 1.4.9.1 Basic information on the block call in SCL


#### 1.4.9.1.1 Calling function blocks


Syntax of a call
The following syntax is used to call a function block as a single or multi-instance:
Single instance:
- If the function block originates from the project:
  <DBName> (Parameter list)
- If the function block originates from the "Instructions" task card:
  <DB name>.<Instruction name> (Parameter list)
  or
  <Instruction name> (Parameter list)
  Multi-instance
  <#Instance name> (Parameter list)

Calling as single instance or multi-instance
Function blocks can be called either as a single instance or a multi-instance.
Calling as a single instance
The called function block stores its data in a data block of its own.
Calling as a multi-instance
The called function block stores its data in the instance data block of the calling function
block.
For additional information on the types of calls, refer to "See also".

Recursive block calls
You have the option of calling a block recursively. This means a block can call itself again. Keep
in mind that the call depth is limited to 24 and that you cannot use multi-instances.

Parameter list
If you call another code block from a SCL block, you can supply the formal parameters of the
called block with actual parameters.
The specification of the parameters has the form of a value assignment. This value assignment
enables you to assign values (actual parameters) to the parameters you have defined in the
called block.


The formal parameters of the called code block are listed in brackets directly after the call. Input
and in-out parameters have the assignment identifier ":=", output parameters have the
assignment identifier "=>". A placeholder placed after the parameter shows the required data
type and the type of the parameter.

Rules for supplying parameters
The following rules apply to supplying parameters:
Constants, tags and expressions can be used as actual parameters.
The assignment order is not of importance.
The data types of formal and actual parameters match. You can also select data types for the
actual parameter for which implicit data type conversion into the data type of the formal
parameter is possible.
The individual assignments are separated by commas.
If the called block has only one parameter, it is sufficient to specify the actual parameter in
the brackets. The formal parameter need not be specified.
See also
Manually inserting block calls
Inserting block calls with drag-and-drop
Block calls
Using and addressing operands
Examples for calling a function block in SCL


#### 1.4.9.1.2 Calling functions


Syntax of a call
The following syntax is used to call a function:
<Function name> (Parameter list); //Standard call
<Operand>:=<Function name> (Parameter list); // Call in an expression

Function value
Functions that provide a return value can be used in any expression in place of an operand in
SCL. For this reason, the return value is also known as the "function value" in SCL.
The call options of functions depend on whether the function returns a function value to the
calling block.
The function value is defined in the RET_VAL parameter. If the RET_VAL parameter is of the VOID
data type, then the function will not return a value to the calling block. If the RET_VAL
parameter has another data type, then the function returns a function value of this data type.


In SCL, all data types are permitted for the RET_VAL parameter except ANY, ARRAY, STRUCT and
VARIANT, as well as the parameter types TIMER and COUNTER.

Call options
There are two possibilities for calling functions in SCL:
Standard call for functions with and without a function value
With a standard call, the results of the function is made available as an output and in-out
parameter.
Call in an expression for functions with a function value
Functions that return a function value can be used in any expression in place of an operand,
for example, a value assignment.
The function calculates the function value, which has the same name as the function and
returns it to the calling block. There the value replaces the function call.
Following the call, the results of the function is made available as a function value or as an
output and in-out parameter.

Recursive block calls
You have the option of calling a block recursively. This means a block can call itself again. Keep
in mind that the call depth is limited to 24 and that you cannot use multi-instances.

Parameter list
If you call another code block from a SCL block, you need to supply the formal parameters of the
called block with actual parameters.
The specification of the parameters has the form of a value assignment. This value assignment
enables you to assign values (actual parameters) to the parameters you have defined in the
called block.
The formal parameters of the called code block are listed in brackets directly after the call. Input
and in-out parameters have the assignment identifier ":=", output parameters have the
assignment identifier "=>". A gray placeholder placed after the parameter shows the required
data type and the type of the parameter.

Rules for supplying parameters
The following rules apply to supplying parameters to functions:
All parameters of the function must be supplied.
The assignment order is not of importance.
Constants, tags and expressions can be used as actual parameters.


The data types of formal and actual parameters match. You can also select data types for the
actual parameter for which implicit data type conversion into the data type of the formal
parameter is possible.
The individual assignments are separated by commas.
If the called block has only one parameter, it is sufficient to specify the actual parameter in
the brackets. The formal parameter need not be specified.
When you call functions in SCL, you cannot use the release mechanism via EN. Use an IF
statement instead to call functions conditionally.
See also
Manually inserting block calls
Inserting block calls with drag-and-drop
Block calls
Using and addressing operands
Examples for calling functions in SCL


#### 1.4.9.1.3 Examples for calling a function block in SCL


Calling as a single instance
The following example shows the call of an FB as a single instance:


```scl
// Call as a single instance
"MyDB" (MyInput:=10, MyInout:= "Tag1");

```

Result
After the call is executed, the value determined for the "MyInout" in/out parameter is available in
"Tag1" in the "MyDB" data block.

Calling as a multi-instance
The following example shows the call of an FB as a multi-instance:


```scl
// Call as a multi-instance
#MyFB (MyInput:= 10, MyInout:= "Tag1");

```

Result


After the "#MyFB" block is executed, the value determined for the "MyInout" in/out parameter is
made available in "Tag1" in the data block of the calling code block.
See also
Calling function blocks
Manually inserting block calls
Inserting block calls with drag-and-drop
Block calls
Using and addressing operands


#### 1.4.9.1.4 Examples for calling functions in SCL


Standard call
The following example shows a standard function call:


```scl
// Standard function call
"MyFC" (MyInput := 10, MyInOut := "Tag1");

```

Result
After the "MyFC" block is executed, the value determined for the "MyInOut" in/out parameter is
available in "Tag1" in the calling block and needs to be further processed there.

Call in a value assignment
The following example shows a function call in a value assignment:


```scl
(*Call in a value assignment, a function value was defined
for "MyFC" *)
#MyOperand := "MyFC" (MyInput1 := 3, MyInput2 := 2, MyInput3
:= 8.9, MyInOut := "Tag1");

```

Result
The function value of "MyFC" is transferred to "#MyOperand".

Call in an arithmetic expression
The following example shows a function call in an arithmetic expression:


```scl
(*Call in a mathematical expression, a function value was
defined for "MyFC" *)
#MyOperand := "Tag2" + "MyFC" (MyInput1 := 3, MyInput2 := 2,
MyInput3 := 8.9);

```

Result
The function value of "MyFC" will be added to "Tag2" and the result will be transferred to
"MyOperand".
See also
Calling functions
Manually inserting block calls
Inserting block calls with drag-and-drop


#### 1.4.9.2 Manually inserting block calls

You can insert calls for functions (FCs) and function blocks (FBs). Function blocks can be called
either as a single, multi or parameter instance.
See also: Basics of instances

Inserting a call for a function (FC)
Proceed as follows to insert a function call:
1. Enter the function name.
2. Confirm your entry with the Enter key.
3. Select the "Show all parameters" command from the context menu or press the key
   combination <Ctrl+Shift+space bar>. Alternatively, you can click "Expands/collapses the
   parameter list of block calls" in the function bar.
   The syntax for the function call including the parameter list is added to the SCL program.
   The placeholders for the actual parameters are highlighted in yellow. The first placeholder is
   selected.
4. Replace this placeholder with an actual parameter. You can also drag a tag from the interface
   or the PLC tag table with drag-and-drop to the placeholder.
5. Use the <TAB> key to navigate to all other placeholders and replace them with actual
   parameters. You can navigate to the previous placeholder with <Shift + TAB>.

Inserting a call for a function block (FB)
To insert a call for a function block (FB), follow these steps:


1. Enter the name of the function block.
2. Enter an opening parenthesis "(".
   The "Call options" dialog opens.
3. Confirm your entries with "OK".
   The syntax for the function block call including the parameter list is added to the SCL
   program. The placeholders for the actual parameters are highlighted in yellow. The first
   placeholder is selected.
4. In the dialog, enter whether you want to call the block as a single, multi or parameter
   instance.
   If you click the "Single instance" button, enter a name for the data block that will be
   assigned to the call in the entry field "Name".
   If you call a block that contains monitoring, assign a ProDiag function block to the
   monitoring functions in the "ProDiag FB" text box.
   If you click the "Multi-instance" button, in the "Name in the interface" field, enter the
   name of the tag with which the called function block will be entered as a static tag in the
   interface of the calling block.
   If you click on the "Parameter instance" button, enter the name of the in/out (InOut)
   parameter to which the instance should be passed during runtime in the "Name in the
   interface" text box.
5. Replace this placeholder with an actual parameter. You can also drag a tag from the interface
   or the PLC tag table with drag-and-drop to the placeholder.
6. Use the <TAB> key to navigate to all other placeholders and replace them with actual
   parameters. You can navigate to the previous placeholder with <Shift + TAB>.

Result
The block call is inserted.
If you specify an instance data block that does not exist when calling a function block, it is
created.
See also
Updating block calls
Expanding and reducing the parameter list
Basic information on the block call in SCL
Block calls
Using autocompletion in textual programming languages


#### 1.4.9.3 Inserting block calls with drag-and-drop

You can insert calls for existing functions (FC) and function blocks (FB) using a drag-and-drop
operation from the project tree.


Function blocks can be called either as a single, multi or parameter instance.
See also: Basics of instances

Requirement
The function to be called (FC) or the function block (FB) to be called is present.

Inserting a call for a function (FC)
To insert a function call using drag-and-drop, follow these steps:
1. Drag the function from the project tree into the program.
   The syntax for the function call including the parameter list is added to the SCL program.
   The placeholders for the actual parameters are highlighted in yellow. The first placeholder is
   selected.
2. Replace this placeholder with an actual parameter. You can also drag a tag from the interface
   or the PLC tag table with drag-and-drop to the placeholder.
3. Use the <TAB> key to navigate to all other placeholders and replace them with actual
   parameters. You can navigate to the previous placeholder with <Shift + TAB>.

Inserting a call for a function block (FB)
To insert a call for a function block (FB) using drag-and-drop, follow these steps:
1. Drag the function block from the project tree and drop it into the program.
   The "Call options" dialog opens.
2. In the dialog, enter whether you want to call the block as a single, multi or parameter
   instance.
   If you click the "Single instance" button, enter a name for the data block that will be
   assigned to the call in the entry field "Name".
   If you call a block that contains monitoring, assign a ProDiag function block to the
   monitoring functions in the "ProDiag FB" text box.
   If you click the "Multi-instance" button, in the "Name in the interface" field, enter the
   name of the tag with which the called function block will be entered as a static tag in the
   interface of the calling block.
   If you click on the "Parameter instance" button, enter the name of the in/out (InOut)
   parameter to which the instance should be passed during runtime in the "Name in the
   interface" text box.
3. Confirm your entries with "OK".
   The syntax for the function block call including the parameter list is added to the SCL
   program. The placeholders for the actual parameters are highlighted in yellow. The first
   placeholder is selected.


4. Replace this placeholder with an actual parameter. You can also drag a tag from the interface
or the PLC tag table with drag-and-drop to the placeholder.
5. Use the <TAB> key to navigate to all other placeholders and replace them with actual
   parameters. You can navigate to the previous placeholder with <Shift + TAB>.

Result
The block call is inserted.
If you specify an instance data block that does not exist when calling a function block, it is
created.
See also
Updating block calls
Expanding and reducing the parameter list
Basic information on the block call in SCL
Block calls
Using autocompletion in textual programming languages


#### 1.4.9.4 Updating block calls

If interface parameters of a called block are changed, the block call can no longer be executed
correctly. You can avoid such inconsistent block calls by updating the block calls.
You have the following options for updating the block calls:
Explicit updating of all inconsistent block calls in the programming editor.
The inconsistent block calls within the open block are updated. The following actions are
carried out in the process:
- New parameters are added. Please note, however, that the parameters are hidden for
  function blocks (FBs) and the parameters are supplied via the corresponding instance
  data block (DB). If required, you can show the parameters using the shortcut menu
  command "Show all parameters".
- Deleted parameters are not removed. If necessary, expand the parameter list to remove
  deleted parameters manually.
- Renamed parameters get the new parameter names.

Note
If updating all inconsistent block calls would cause an error in the parameter
supply, you cannot use the "Update block calls" command. If this is the case,
update each block call individually.
Explicit updating of a block call in the programming editor.


The inconsistent call of this block is updated at all call locations. The following actions are
carried out in the process:
- New parameters are added.
- Deleted parameters are not removed. If necessary, expand the parameter list to remove
  deleted parameters manually.
- Renamed parameters get the new parameter names.
  Implicit updating during compilation.
  All block calls in the program as well as the used PLC data types will be updated. Make sure
  that you manually remove deleted parameters before the compilation process and supply all
  new formal parameters with actual parameters when you call functions.

Updating all inconsistent block calls in the programming editor
To update all block calls in a block, follow these steps:
1. Open the calling block in the programming editor.
2. Click "Update inconsistent block calls" in the toolbar.
   All inconsistent calls are updated. If necessary, supply new formal parameters of functions
   (FCs) with actual parameters.

Updating a specific block call in the programming editor
To update a specific block call in the programming editor, follow these steps:
1. Open the calling block in the programming editor.
2. Right-click on the block call that you want to update.
3. Select the "Update block call" command in the shortcut menu.
4. If parameters were added, enter the values for the new block parameters.

Note
Note that the "Update block call" command is only available as long as you did not
previously update all block calls in the editor with the "Update inconsistent block
calls" command.

Updating block calls during compilation
To implicitly update all block calls and uses of PLC data types during compilation, follow these
steps:
1. Open the project tree.
2. Select the "Program blocks" folder.
3. Select the "Compile > Software (rebuild all blocks)" command in the shortcut menu.


See also
Manually inserting block calls
Inserting block calls with drag-and-drop
Expanding and reducing the parameter list


### 1.4.10 Expanding and reducing the parameter list

In SCL, if you call blocks or insert instructions that are system-internal function blocks, the
syntax and the parameter list with the placeholders for the actual parameters are inserted in the
SCL program. To make the program code easier to read, the unused optional parameters are
removed from the parameter list when you edit other instructions. You can restore these at any
time. You can also explicitly reduce the parameter list when you have finished assigning the
parameters.

Expanding the parameter list
To expand the parameter list, follow these steps:
1. Right-click in the block call or the instruction.
2. Select the "Expand parameter list" command from the shortcut menu or press the key
   combination <Ctrl+Shift+Space bar>.
   The parameter list is displayed in full again.

Reducing the parameter list
To reduce the parameter list, follow these steps:
1. Right-click in the block call or the instruction.
2. Select the "Reduce parameter list" command from the shortcut menu or press the key
   combination <Ctrl+Shift+Space bar>.
   All unused optional parameters are hidden.
   See also
   Entering SCL instructions manually
   Inserting SCL instructions using the "Instructions" task card
   Manually inserting block calls
   Inserting block calls with drag-and-drop


### 1.4.11 Insert pragmas (S7-1200, S7-1500)

You have the option of assigning validities to your program code using pragmas. To do so,
surround the program code with Pragma keywords and assign at least one parameter.
Optionally, you can assign additional parameters to define the content. Note that the character


"$" is used as escape sequence in string constants and cannot therefore be used as normal sign
for the parameter name.
The general syntax for pragmas is as follows:

{PRAGMA_BEGIN 'Param1', 'Param2', ... , 'ParamN'}
//Programcode
{PRAGMA_END}
Pragmas can also be nested. However, make sure that pragmas within other pragmas are
successfully completed. Pragmas can be expanded and collapsed as needed.

Note
Pragmas are currently evaluated only in SiVArc. The "SIVARC" parameter and
another parameter must be assigned.
For more information, refer to the SiVArc help.

Procedure
To insert a pragma, follow these steps:
1. Place the cursor at the position where you want to insert a pragma.
2. Enter "{ PRAGMA_BEGIN".
3. Enter at least one parameter with single quotation marks.
4. Enter any number of additional parameters in single quotation marks. This step is optional.
5. Enter "}".
6. Place the cursor at the end of the program code that you want to surround with the pragma.
7. Enter "{ PRAGMA_END}".
   The corresponding program code is combined in a pragma.


### 1.4.12 Inserting comments


Commenting program code
You have various options for commenting SCL programs:
Line comment
A line comment starts with "//" and extends to the end of the line.
Comment section
A comment section is started with "(* and completed by "*)". It can span several lines.


Multilingual comments
Multilingual comments are comments that you can translate into other project languages. A
multilingual comment is started with "(/*" and ended with "*/)" and forms a unit. This means
you can always only mark or select the entire comment and not parts of it. Multilingual
comments cannot be nested into one another but you can use them within line comments
and comment sections. By contrast, you cannot use line comments or simple comment
sections within multilingual comments because everything between "(/*" and "*/)" is
interpreted as normal text.
You can find additional information on "Multilingualism" in the following sections:
- "Working with multi-language projects"
- "Editing multilingual project texts in blocks"

Inserting a line comment
To insert line comments, follow these steps:
1. Type "//" at the position where you want to place the comment. This does not have to be the
   beginning of the line.
2. Enter the comment text.

Inserting a comment section
To insert a comment section, follow these steps:
1. Type "(*" at the position where you want to place the comment. This does not have to be the
   beginning of the line.
2. Enter the comment text.
3. Complete the comment with "*)".
   Alternatively, you can also convert existing program code into a comment section later:
1. Select the program code that you want to convert into a comment section.
2. Right-click the selected program code.
3. In the shortcut menu, select the entry "(* *)" under "Surround with". Or select the instruction
   "(* *)" in the "Instructions" task card in the "Simple instructions > Program control" pane.

Inserting multilingual comment
To insert a multilingual comment, follow these steps:
1. Type "(/*" at the position where you want to place the multilingual comment. This does not
   have to be the beginning of the line.
   The editor automatically inserts the comment end "*/)".
2. Enter the comment text.


Disabling one or more lines with comments
To disable program code with comments, follow these steps:
1. Select the code lines you want to comment out.
2. Click the "Comments out the selected lines" button in the editor.
   "//" is inserted at the beginning of the line in the selected lines. The code that follows is
   interpreted as a comment. If lines already containing a line comment are disabled, "//" is
   inserted as well. If these lines are enabled again, the original comments are retained. If the
   selected line contains only a multilingual comment, the line is not commented out and no
   "//" is inserted at the beginning of the line. However, if additional code follows the
   multilingual comment, the line is commented out from the code. In this case, "//" is inserted
   immediately before the code.

Enabling comment lines
To enable lines that have been commented out to be enabled as code again, proceed as follows:
1. Select the code lines you want to enable.
2. Click the "Remove comment" button in the editor.
   The "//" mark for line comments at the beginning of the line is removed.

Example
The following code shows the use of various types of comments:

(***********************************************************************
A description of the instructions that follow can be placed here

************************************************************************
IF "MyVal1" > 0 THEN //No division by 0
"MyReal" := "MyVal2" (* input value *) / "MyVal1" (* measured value *);
END_IF;
(/*data type conversion*/)
//"MyInt" := REAL_TO_INT("MyReal2");
"MyInt" := REAL_TO_INT("MyReal");
See also
(*...*): Insert a comment section (S7-1200, S7-1500, S7-1200 G2)
Surround program code with structure elements
(/*...*/): Insert multilingual comment (S7-1200, S7-1500, S7-1200 G2)
(/*...*/): Insert multilingual comment (S7-300, S7-400)


## 1.5 Editing SCL instructions


### 1.5.1 Selecting instructions

You can select individual instructions or all instructions of a block.

Requirement
An SCL block is open.

Selecting individual instructions
To select individual instructions, follow these steps:
1. Set the insertion mark before the first character that you want to select.
2. Press and hold down the left mouse button.
3. Move the cursor to a position after the last character that you want to select.
4. Release the left mouse button.

Selecting all the instructions of a program
To select all instructions, follow these steps:
1. In the "Edit" menu, select the "Select All" command or use the keyboard shortcut <Ctrl+A>.

Note
When you select the opening keyword of an instructing, the closing keyword is
automatically highlighted.


### 1.5.2 Copying, cutting and pasting instructions


Copying an instruction
To copy an instruction, follow these steps:
1. Select the instruction you want to copy.
2. Select "Copy" in the shortcut menu.

Cutting an instruction
To cut an instruction, follow these steps:
1. Select the instruction you want to cut.
2. Select the "Cut" command in the shortcut menu.


Inserting an instruction from the clipboard
To insert an instruction from the clipboard, follow these steps:
1. Copy or cut an instruction.
2. Click on the position at which you want to insert the instruction.
3. Select "Paste" in the shortcut menu.


### 1.5.3 Deleting instructions


Requirement
An SCL block is open.

Procedure
To delete an instruction, follow these steps:
1. Select the instruction you want to delete.
2. Select the "Delete" command in the shortcut menu.


## 1.6 SCL programming examples


### 1.6.1 Example of controlling a conveyor belt


Controlling a conveyor belt
The following figure shows a conveyor belt that can be activated electrically. There are two
pushbuttons at the beginning of the conveyor belt: S1 for START and S2 for STOP. There are also
two pushbuttons at the end of the conveyor belt: S3 for START and S4 for STOP. It is possible to
start and stop the conveyor belt from either end.

Implementation
The following table shows the definition of the tags used:


Operand

Declaration

Data type

Description

StartPushbutton_Left

Input

BOOL

Start pushbutton

(S1)

on the left side of
the conveyor belt

StopPushbutton_Left

Input

BOOL

(S2)

Stop pushbutton
on the left side of
the conveyor belt

StartPushbutton_Right

Input

BOOL

(S3)

Start pushbutton
on the right side of
the conveyor belt

StopPushbutton_Right

Input

BOOL

(S4)

Stop pushbutton
on the right side of
the conveyor belt

MOTOR_ON

Output

BOOL

Turn on the
conveyor belt
motor

MOTOR_OFF

Output

BOOL

Turn off the
conveyor belt
motor

The following SCL program shows how to implement this task:


```scl
IF "StartPushbutton_Left_S1" OR "StartPushbutton_Right_S3"
THEN
"MOTOR_ON" := 1;
"MOTOR_OFF" := 0;
END_IF;
IF "StopPushbutton_Left_S2" OR "StopPushbutton_Right_S4" THEN
"MOTOR_ON" := 0;
"MOTOR_OFF" := 1;
END_IF;


The conveyor belt motor is switched on when start pushbutton "StartPushbutton_Left_S1" or
"StartPushbutton_Right_S3" is pressed. The conveyor belt motor is switched off when stop
pushbutton "StopPushbutton_Left_S2" or "StopPushbutton_Right_S4" is pressed.
```

See also
Logical expressions
Basics of SCL
Settings for SCL
The programming window of SCL
Entering SCL instructions
Editing SCL instructions


### 1.6.2 Example of detecting the direction of a conveyor belt


Detecting the direction of a conveyor belt
The detected running direction of the belt is indicated by a RIGHT arrow or a LEFT arrow. If
additional conveyed material is approaching PEB1 from the right or PEB2 from the left, the
displayed arrow is initially switched off until, after both photoelectric barriers are passed, the
running direction can be detected again and the corresponding arrow displayed. For the solution
of the task, 2 edge memory bits are needed that detect the signal change from "0" to "1" at the
two photoelectric barriers.

Implementation
The following table shows the definition of the tags used:
Name

Declaration

Data type

Description

Photoelectric

Input

BOOL

Photoelectric

barrier PEB1
Photoelectric
barrier PEB2


barrier 1
Input

BOOL

Photoelectric
barrier 2


RIGHT

Output

BOOL

Display for movement to the right

LEFT

Output

BOOL

Display for movement to the left

Auxiliary flag PEB1

Input

BOOL

Edge bit memory 1

Auxiliary flag PEB2

Input

BOOL

Edge bit memory 2

The following SCL program shows how to implement this example:


```scl
// Program code for left running
IF "Photolelectric barrier PEB1"​= 1 AND "Auxiliary flag
PEB2" = 0 THEN
"Auxiliary flag PEB1" := 1; // Set auxiliary flag for PEB1
"LEFT" := 0; // Switch off arrow display left
"RIGHT" := 0; // Switch off arrow display right
END_IF;
IF "Auxiliary flag PEB1"​= 1 AND "Photoelectric barrier PEB2"
= 1 THEN // The conveyor belt is running to the left
"LEFT" = 1;
"RIGHT" := 0;
END_IF;
IF "LINKS" = 1 AND "Photoelectric barrier PEB2" = 0 THEN //
Reset auxiliary flag for PEB1
"Auxiliary flag PEB1" = 0
END_IF;
SCL
// Program code for right running


IF "Photolelectric barrier PEB2"​= 1 AND "Auxiliary flag
PEB1" = 0 THEN
"Auxiliary flag PEB2" := 1; // Set auxiliary flag for PEB2
"LEFT" := 0; // Switch off arrow display left
"RIGHT" := 0; // Switch off arrow display right
END_IF;
IF "Auxiliary flag PEB2"​= 1 AND "Photoelectric barrier PEB1"
= 1 THEN // The conveyor belt is running to the right
"LEFT" = 0;
"RIGHT" := 1;
END_IF;
IF "RIGHT" = 1 AND "Photoelectric barrier PEB1" = 0 THEN //
Reset auxiliary flag for PEB2
"Auxiliary flag PEB2" := 0;
END_IF;
```

If the photoelectric barrier "PEB1" has signal state "1" and the photoelectric barrier "PEB2" has
signal state "0" at the same time, the object on the belt is moving to the left. If the photoelectric
barrier "PEB2" has signal state "1" and the photoelectric barrier "PEB1" has signal state "0" at the
same time, the object on the belt is moving to the right. The displays for a movement to the left
or right will be turned off when the signal state at both photoelectric barriers is "0".
See also
Logical expressions
Basics of SCL
Settings for SCL
The programming window of SCL
Entering SCL instructions
Editing SCL instructions


### 1.6.3 Example of detecting the fill level of a storage area


Detecting the fill level of a storage area


The following figure shows a system with two conveyor belts and a temporary storage area
between them. Conveyor belt 1 delivers packages to the storage area. A photoelectric barrier at
the end of conveyor belt 1 near the storage area detects how many packages are delivered to
the storage area. Conveyor belt 2 transports packages from the temporary storage area to a
loading dock where they are loaded onto trucks. A photoelectric barrier at the storage area exit
detects how many packages leave the storage area to be transported to the loading dock. Five
display lamps indicate the capacity of the temporary storage area.

Implementation
The following table shows the definition of the tags used:
Name

Declaration

Data type

Description

PEB1

Input

BOOL

Photoelectric
barrier 1

PEB2

Input

BOOL

Photoelectric
barrier 2

RESET

Input

BOOL

Reset counter

LOAD

Input

BOOL

Adjust the current
counter value to
the value of the PV
parameter​.


MAX STORAGE AREA

Input

INT

FILL AMOUNT
PACKAGECOUNT

Maximum possible number of packages in
the storage area

Output

INT

Number of packages in the storage area
(current count value)

STOCK_PACKAGES

Output

BOOL

Is set when the current count value is
greater than or equal to the value of the
"MAX STORAGE AREA FILL AMOUNT" tag.

STOR_EMPTY

Output

BOOL

Display lamp: Storage area empty

STOR_NOT_EMPTY

Output

BOOL

Display lamp: Storage area not empty

STOR_50%_FULL

Output

BOOL

Display lamp: Storage area 50 % full

STOR_90%_FULL

Output

BOOL

Display lamp: Storage area 90 % full

STOR_FULL

Output

BOOL

Display lamp: Storage area full

VOLUME_50

Input

INT

Comparison value: 50 packages

VOLUME_90

Input

INT

Comparison value: 90 packages

VOLUME_100

Input

INT

Comparison value: 100 packages

The following SCL program shows how to implement this example:
When a package is delivered to the storage area, the signal state at "PEB1" switches from "0" to
"1" (positive signal edge). On a positive signal edge at "PEB1", the "Up" counter is enabled, and
the current count value of "PACKAGECOUNT" is increased by one.
When a package is delivered from the storage area to the loading dock, the signal state at "PEB2"
switches from "0" to "1" (positive signal edge). On a positive signal edge at "PEB2", the "Down"
counter is enabled, and the current count value of "PACKAGECOUNT" is decreased by one.
If there are no packages in the storage area ("PACKAGECOUNT" = "0"), the "STOR_EMPTY" tag is
set to signal state "1", and the "Storage area empty" lamp is switched on.
The current count value can be reset to "0" if the "RESET" tag is set to signal state "1".
If the "LOAD" tag is set to signal state "1", the current count value is set to the value of the "MAX
STORAGE AREA FILL AMOUNT" tag. As long as the current count value is greater than or equal to
the value of the "MAX STORAGE AREA FILL AMOUNT" tag, the "STOCK_PACKAGES" tag supplies
the signal state "1".


```scl


"VOLUME_50" := 5; // Preassigning of the comparison value to
50 packages (for the test only 5 packages)
"VOLUME_90" := 9; // Preassigning of the comparison value to
90 packages (for the test only 9 packages)
"VOLUME_100" := 10; // Preassigning of the comparison value
to 100 packages (for the test only 10 packages)
"MAX STORAGE AREA FILL AMOUNT" := 10; // Preassigning of the
maximum amount in storage area to 100 packages (for the test
only 10 packages)
"IEC_Counter_0_DB".CTUD(CU := "PEB1",
CD := "PEB2",
R := "RESET",
LD := "LOAD",
PV := "MAX STORAGE AREA FILL AMOUNT",
QU => "STOCK_PACKAGES",
QD => "STOR_EMPTY",
CV => "PACKAGECOUNT");
```

As long as the storage area contains packages, the "Storage area not empty" lamp is switched
on.


```scl
"STOR_NOT_EMPTY" := NOT "STOR_EMPTY"​
If the number of packages in the storage area is lower than 50%, the lamps for the alarms
"Storage area 50% full", "Storage area 90% full" and "Storage area full" switch off.

SCL
IF "PACKAGECOUNT" < "VOLUME_50" THEN
"STOR_50%_FULL" := 0;
"STOR_90%_FULL" := 0;


"STOR_FULL" := 0;
END_IF;
```

If the number of packages in the storage area is greater than or equal to 50 %, the "Storage area
50 % full" lamp switches on.


```scl
IF "PACKAGECOUNT" >= "VOLUME_50" AND "PACKAGECOUNT <=
"VOLUME_90" THEN
"STOR_50%_FULL" := 1;
"STOR_90%_FULL" := 0;
"STOR_FULL" := 0;
END_IF;
```

If the number of packages in the storage area is greater than or equal to 90 %, the "Storage area
90 % full" lamp switches on. The display lamp for 50 % full also remains on.


```scl
IF "PACKAGECOUNT" >= "VOLUME_90" AND "PACKAGECOUNT <
"VOLUME_100" THEN
"STOR_50%_FULL" := 1;
"STOR_90%_FULL" := 1;
"STOR_FULL" := 0;
END_IF;
```

If the number of packages in the storage area reaches 100 %, the lamp for the "Storage area full"
message switches on. The display lamps for 50 % and 90 % full also remain on.


```scl
IF "PACKAGECOUNT" >= "VOLUME_100" THEN
"STOR_50%_FULL" := 1;
"STOR_90%_FULL" := 1;


"STOR_FULL" := 1;
END_IF;
```

See also
Basics of SCL
Settings for SCL
The programming window of SCL
Entering SCL instructions
Editing SCL instructions


