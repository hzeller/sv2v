{- sv2v
 - Author: Zachary Snow <zach@zachjs.com>
 -
 - Verilog-2005 forbids block declarations with default values. We convert
 - these assignments to separate statements. If we handle static lifetimes in
 - the future, this conversion may have to change.
 -}

module Convert.BlockDecl (convert) where

import Data.Maybe (mapMaybe)

import Convert.Traverse
import Language.SystemVerilog.AST

convert :: [AST] -> [AST]
convert =
    map
    $ traverseDescriptions $ traverseModuleItems
    $ traverseStmts $ convertStmt

convertStmt :: Stmt -> Stmt
convertStmt (Block name decls stmts) =
    Block name decls' stmts'
    where
        splitDecls = map splitDecl decls
        decls' = map fst splitDecls
        asgns = map asgnStmt $ mapMaybe snd splitDecls
        stmts' = asgns ++ stmts
convertStmt other = other

splitDecl :: Decl -> (Decl, Maybe (LHS, Expr))
splitDecl (Variable d t ident a (Just e)) =
    (Variable d t ident a Nothing, Just (LHSIdent ident, e))
splitDecl other = (other, Nothing)

asgnStmt :: (LHS, Expr) -> Stmt
asgnStmt = uncurry $ AsgnBlk AsgnOpEq
