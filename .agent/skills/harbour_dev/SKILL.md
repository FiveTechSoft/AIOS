---
name: Harbour & HIX Development 
description: Critical rules for coding and compiling Harbour (.prg) files in this environment.
---

# Harbour Development Rules

## 1. Indentation Rules (CRITICAL)
Always respect block indentation in `.prg` files. Do not write flat code. **CRITICALLY IMPORTANT: ALL INDENTATION MUST BE EXACTLY 3 (THREE) SPACES.** Never 4 spaces. Never tabs. Always 3 spaces per level.
- If you write an `if ... else ... elseif ... endif` block, a `do while ... enddo` loop, a `for ... next` loop, or a `do case ... case ... endcase` structure, the code inside the branches MUST be indented to the right (exactly 3 spaces).
- Examples of correctly indented code:
```harbour
if nError == HB_CURLE_OK
    cResponse := curl_easy_dl_buff_get(hCurl)
    if !Empty(cResponse)
        LogTrace("Success")
    endif
else
    LogTrace("Error: " + Str(nError))
endif
```

## 2. Hash Map Syntax
In Harbour, use `=>` to define key-value pairs in hash maps, not `:`. 
- **Correct**: `{ "key" => "value" }`
- **Incorrect**: `{ "key": "value" }` (This generates runtime/compile JSON mapping errors).

## 3. Compiler Command & Location
To compile Harbour scripts in this workspace, you MUST use exactly the following compiler executable:
`c:\harbour\bin\win\bcc\hbmk2.exe [filename.prg]`

## 4. BCC Environment Setup
Before executing `hbmk2.exe`, you must ALWAYS ensure the Borland C++ compiler (`bcc32c`) is in your path. If you do this in a single command line, combine them:
`set PATH=c:\bcc77\bin;%PATH% && c:\harbour\bin\win\bcc\hbmk2.exe aios.prg`

## 5. Dependencies & HBC Files
If using network/web features like UGet, UWrite, or curl, remember to compile with the necessary harbour libraries by appending the `.hbc` configurations to the command line:
`c:\harbour\bin\win\bcc\hbmk2.exe aios.prg hbcurl.hbc xhb.hbc hbhttpd.hbc`

## 6. Keywords
In Harbour, always use the full keyword `return` instead of the abbreviation `retu`.

## 7. Function and Local Variables Spacing (CRITICAL)
**CRITICALLY IMPORTANT:** You must rigorously apply this spacing rule to every single `function` and `procedure` in the `.prg` files.
- You MUST leave exactly **ONE BLANK EMPTY LINE** immediately after a `function` or `procedure` declaration, before starting with the `local` variables blocks. 
- You MUST leave exactly **ONE BLANK EMPTY LINE** exactly after the `local` variable definition blocks to separate them from the rest of the body code.
- Example:
```harbour
function Example()

   local nVar := 1
   local cTxt := "test"

   if nVar == 1
      LogTrace(cTxt)
   endif
return nil
```

## 8. Logical NOT Operator (!)
Whenever you use the logical NOT operator `!`, you **MUST** leave exactly one space after it.
- **Correct**: `if ! Empty( cVar )`
- **Incorrect**: `if !Empty(cVar)`

## 9. Parentheses Spacing
Whenever you use parentheses `( )`, you **MUST** leave exactly one space after the opening parenthesis `(` and exactly one space before the closing parenthesis `)`.
- **Correct**: `if ( nVar == 1 )` or `hb_HGetDef( hArgs, "query", "" )`
- **Incorrect**: `if (nVar == 1)` or `hb_HGetDef(hArgs, "query", "")`

## 10. Comments Language
All code comments within `.prg` files MUST be strictly written in English. Do not write comments in Spanish or any other language.
