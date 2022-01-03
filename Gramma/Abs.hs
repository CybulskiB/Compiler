-- File generated by the BNF Converter (bnfc 2.9.3).

{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE OverloadedStrings #-}

-- | The abstract syntax of language Gramma.

module Gramma.Abs where

import qualified Prelude as C (Eq, Ord, Show, Read)
import qualified Data.String

import qualified Data.Text

data Program = Program [Declaration] [Command]
  deriving (C.Eq, C.Ord, C.Show, C.Read)

data Declaration
    = ScalarDecl Pidentifier | ArrayDecl Pidentifier Number Number
  deriving (C.Eq, C.Ord, C.Show, C.Read)

data Command
    = Assign Identifier Expression
    | IfElse Condition [Command] [Command]
    | While Condition [Command]
    | Repeat [Command] Condition
    | ForTo Pidentifier Value Value [Command]
    | ForDownTo Pidentifier Value Value [Command]
    | Read Identifier
    | Write Value
  deriving (C.Eq, C.Ord, C.Show, C.Read)

data Expression
    = ValueExpr Value
    | Plus Value Value
    | Minus Value Value
    | Times Value Value
    | Div Value Value
    | Mod Value Value
  deriving (C.Eq, C.Ord, C.Show, C.Read)

data Condition
    = Eq Value Value
    | Neq Value Value
    | Le Value Value
    | Ge Value Value
    | Leq Value Value
    | Geq Value Value
  deriving (C.Eq, C.Ord, C.Show, C.Read)

data Value = NumValue Number | IdValue Identifier
  deriving (C.Eq, C.Ord, C.Show, C.Read)

data Identifier
    = ScalarId Pidentifier
    | VarArrayId Pidentifier Pidentifier
    | ConstArrayId Pidentifier Number
  deriving (C.Eq, C.Ord, C.Show, C.Read)

simpleProg :: [Command] -> Program
simpleProg cmds = Program [] cmds

ifElseSkip :: Condition -> [Command] -> Command
ifElseSkip cond cmds = IfElse cond cmds []

newtype Pidentifier = Pidentifier Data.Text.Text
  deriving (C.Eq, C.Ord, C.Show, C.Read, Data.String.IsString)

newtype Number = Number Data.Text.Text
  deriving (C.Eq, C.Ord, C.Show, C.Read, Data.String.IsString)
