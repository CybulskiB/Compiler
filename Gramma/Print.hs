-- File generated by the BNF Converter (bnfc 2.9.3).

{-# LANGUAGE CPP #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE LambdaCase #-}
#if __GLASGOW_HASKELL__ <= 708
{-# LANGUAGE OverlappingInstances #-}
#endif

-- | Pretty-printer for Gramma.

module Gramma.Print where

import Prelude
  ( ($), (.)
  , Bool(..), (==), (<)
  , Int, Integer, Double, (+), (-), (*)
  , String, (++)
  , ShowS, showChar, showString
  , all, elem, foldr, id, map, null, replicate, shows, span
  )
import Data.Char ( Char, isSpace )
import qualified Gramma.Abs
import qualified Data.Text

-- | The top-level printing method.

printTree :: Print a => a -> String
printTree = render . prt 0

type Doc = [ShowS] -> [ShowS]

doc :: ShowS -> Doc
doc = (:)

render :: Doc -> String
render d = rend 0 False (map ($ "") $ d []) ""
  where
  rend
    :: Int        -- ^ Indentation level.
    -> Bool       -- ^ Pending indentation to be output before next character?
    -> [String]
    -> ShowS
  rend i p = \case
      "["      :ts -> char '[' . rend i False ts
      "("      :ts -> char '(' . rend i False ts
      "{"      :ts -> onNewLine i     p . showChar   '{'  . new (i+1) ts
      "}" : ";":ts -> onNewLine (i-1) p . showString "};" . new (i-1) ts
      "}"      :ts -> onNewLine (i-1) p . showChar   '}'  . new (i-1) ts
      [";"]        -> char ';'
      ";"      :ts -> char ';' . new i ts
      t  : ts@(s:_) | closingOrPunctuation s
                   -> pending . showString t . rend i False ts
      t        :ts -> pending . space t      . rend i False ts
      []           -> id
    where
    -- Output character after pending indentation.
    char :: Char -> ShowS
    char c = pending . showChar c

    -- Output pending indentation.
    pending :: ShowS
    pending = if p then indent i else id

  -- Indentation (spaces) for given indentation level.
  indent :: Int -> ShowS
  indent i = replicateS (2*i) (showChar ' ')

  -- Continue rendering in new line with new indentation.
  new :: Int -> [String] -> ShowS
  new j ts = showChar '\n' . rend j True ts

  -- Make sure we are on a fresh line.
  onNewLine :: Int -> Bool -> ShowS
  onNewLine i p = (if p then id else showChar '\n') . indent i

  -- Separate given string from following text by a space (if needed).
  space :: String -> ShowS
  space t s =
    case (all isSpace t', null spc, null rest) of
      (True , _   , True ) -> []              -- remove trailing space
      (False, _   , True ) -> t'              -- remove trailing space
      (False, True, False) -> t' ++ ' ' : s   -- add space if none
      _                    -> t' ++ s
    where
      t'          = showString t []
      (spc, rest) = span isSpace s

  closingOrPunctuation :: String -> Bool
  closingOrPunctuation [c] = c `elem` closerOrPunct
  closingOrPunctuation _   = False

  closerOrPunct :: String
  closerOrPunct = ")],;"

parenth :: Doc -> Doc
parenth ss = doc (showChar '(') . ss . doc (showChar ')')

concatS :: [ShowS] -> ShowS
concatS = foldr (.) id

concatD :: [Doc] -> Doc
concatD = foldr (.) id

replicateS :: Int -> ShowS -> ShowS
replicateS n f = concatS (replicate n f)

-- | The printer class does the job.

class Print a where
  prt :: Int -> a -> Doc

instance {-# OVERLAPPABLE #-} Print a => Print [a] where
  prt i = concatD . map (prt i)

instance Print Char where
  prt _ c = doc (showChar '\'' . mkEsc '\'' c . showChar '\'')

instance Print String where
  prt _ = printString

printString :: String -> Doc
printString s = doc (showChar '"' . concatS (map (mkEsc '"') s) . showChar '"')

mkEsc :: Char -> Char -> ShowS
mkEsc q = \case
  s | s == q -> showChar '\\' . showChar s
  '\\' -> showString "\\\\"
  '\n' -> showString "\\n"
  '\t' -> showString "\\t"
  s -> showChar s

prPrec :: Int -> Int -> Doc -> Doc
prPrec i j = if j < i then parenth else id

instance Print Integer where
  prt _ x = doc (shows x)

instance Print Double where
  prt _ x = doc (shows x)

instance Print Gramma.Abs.Pidentifier where
  prt _ (Gramma.Abs.Pidentifier i) = doc $ showString (Data.Text.unpack i)
instance Print Gramma.Abs.Number where
  prt _ (Gramma.Abs.Number i) = doc $ showString (Data.Text.unpack i)
instance Print Gramma.Abs.Program where
  prt i = \case
    Gramma.Abs.Program declarations commands -> prPrec i 0 (concatD [doc (showString "VAR"), prt 0 declarations, doc (showString "BEGIN"), prt 0 commands, doc (showString "END")])

instance Print [Gramma.Abs.Declaration] where
  prt _ [] = concatD []
  prt _ [x] = concatD [prt 0 x]
  prt _ (x:xs) = concatD [prt 0 x, doc (showString ","), prt 0 xs]

instance Print Gramma.Abs.Declaration where
  prt i = \case
    Gramma.Abs.ScalarDecl pidentifier -> prPrec i 0 (concatD [prt 0 pidentifier])
    Gramma.Abs.ArrayDecl pidentifier number1 number2 -> prPrec i 0 (concatD [prt 0 pidentifier, doc (showString "["), prt 0 number1, doc (showString ":"), prt 0 number2, doc (showString "]")])

instance Print [Gramma.Abs.Command] where
  prt _ [] = concatD []
  prt _ [x] = concatD [prt 0 x]
  prt _ (x:xs) = concatD [prt 0 x, prt 0 xs]

instance Print Gramma.Abs.Command where
  prt i = \case
    Gramma.Abs.Assign identifier expression -> prPrec i 0 (concatD [prt 0 identifier, doc (showString "ASSIGN"), prt 0 expression, doc (showString ";")])
    Gramma.Abs.IfElse condition commands1 commands2 -> prPrec i 0 (concatD [doc (showString "IF"), prt 0 condition, doc (showString "THEN"), prt 0 commands1, doc (showString "ELSE"), prt 0 commands2, doc (showString "ENDIF")])
    Gramma.Abs.While condition commands -> prPrec i 0 (concatD [doc (showString "WHILE"), prt 0 condition, doc (showString "DO"), prt 0 commands, doc (showString "ENDWHILE")])
    Gramma.Abs.Repeat commands condition -> prPrec i 0 (concatD [doc (showString "REPEAT"), prt 0 commands, doc (showString "UNTIL"), prt 0 condition, doc (showString ";")])
    Gramma.Abs.ForTo pidentifier value1 value2 commands -> prPrec i 0 (concatD [doc (showString "FOR"), prt 0 pidentifier, doc (showString "FROM"), prt 0 value1, doc (showString "TO"), prt 0 value2, doc (showString "DO"), prt 0 commands, doc (showString "ENDFOR")])
    Gramma.Abs.ForDownTo pidentifier value1 value2 commands -> prPrec i 0 (concatD [doc (showString "FOR"), prt 0 pidentifier, doc (showString "FROM"), prt 0 value1, doc (showString "DOWNTO"), prt 0 value2, doc (showString "DO"), prt 0 commands, doc (showString "ENDFOR")])
    Gramma.Abs.Read identifier -> prPrec i 0 (concatD [doc (showString "READ"), prt 0 identifier, doc (showString ";")])
    Gramma.Abs.Write value -> prPrec i 0 (concatD [doc (showString "WRITE"), prt 0 value, doc (showString ";")])

instance Print Gramma.Abs.Expression where
  prt i = \case
    Gramma.Abs.ValueExpr value -> prPrec i 0 (concatD [prt 0 value])
    Gramma.Abs.Plus value1 value2 -> prPrec i 0 (concatD [prt 0 value1, doc (showString "PLUS"), prt 0 value2])
    Gramma.Abs.Minus value1 value2 -> prPrec i 0 (concatD [prt 0 value1, doc (showString "MINUS"), prt 0 value2])
    Gramma.Abs.Times value1 value2 -> prPrec i 0 (concatD [prt 0 value1, doc (showString "TIMES"), prt 0 value2])
    Gramma.Abs.Div value1 value2 -> prPrec i 0 (concatD [prt 0 value1, doc (showString "DIV"), prt 0 value2])
    Gramma.Abs.Mod value1 value2 -> prPrec i 0 (concatD [prt 0 value1, doc (showString "MOD"), prt 0 value2])

instance Print Gramma.Abs.Condition where
  prt i = \case
    Gramma.Abs.Eq value1 value2 -> prPrec i 0 (concatD [prt 0 value1, doc (showString "EQ"), prt 0 value2])
    Gramma.Abs.Neq value1 value2 -> prPrec i 0 (concatD [prt 0 value1, doc (showString "NEQ"), prt 0 value2])
    Gramma.Abs.Le value1 value2 -> prPrec i 0 (concatD [prt 0 value1, doc (showString "LE"), prt 0 value2])
    Gramma.Abs.Ge value1 value2 -> prPrec i 0 (concatD [prt 0 value1, doc (showString "GE"), prt 0 value2])
    Gramma.Abs.Leq value1 value2 -> prPrec i 0 (concatD [prt 0 value1, doc (showString "LEQ"), prt 0 value2])
    Gramma.Abs.Geq value1 value2 -> prPrec i 0 (concatD [prt 0 value1, doc (showString "GEQ"), prt 0 value2])

instance Print Gramma.Abs.Value where
  prt i = \case
    Gramma.Abs.NumValue number -> prPrec i 0 (concatD [prt 0 number])
    Gramma.Abs.IdValue identifier -> prPrec i 0 (concatD [prt 0 identifier])

instance Print Gramma.Abs.Identifier where
  prt i = \case
    Gramma.Abs.ScalarId pidentifier -> prPrec i 0 (concatD [prt 0 pidentifier])
    Gramma.Abs.VarArrayId pidentifier1 pidentifier2 -> prPrec i 0 (concatD [prt 0 pidentifier1, doc (showString "["), prt 0 pidentifier2, doc (showString "]")])
    Gramma.Abs.ConstArrayId pidentifier number -> prPrec i 0 (concatD [prt 0 pidentifier, doc (showString "["), prt 0 number, doc (showString "]")])
