/*
 [The "BSD license"]
 Copyright (c) 2009 Terence Parr
 All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:
 1. Redistributions of source code must retain the above copyright
    notice, this list of conditions and the following disclaimer.
 2. Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in the
    documentation and/or other materials provided with the distribution.
 3. The name of the author may not be used to endorse or promote products
    derived from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
 INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

tree grammar CodeGenerator;

options {
	tokenVocab=STParser;
	ASTLabelType=CommonTree;
}

@header {
package org.stringtemplate.v4.compiler;
import org.stringtemplate.v4.misc.*;
import org.stringtemplate.v4.*;
}

@members {
	String outermostTemplateName; // name of overall template
	CompiledST outermostImpl;
	Token templateToken;
	String template;
	ErrorManager errMgr;
	public CodeGenerator(TreeNodeStream input, ErrorManager errMgr, String name, String template, Token templateToken) {
		this(input, new RecognizerSharedState());
		this.errMgr = errMgr;
		this.outermostTemplateName = name;
		this.template = template;
		this.templateToken = templateToken;
	}

	// convience funcs to hide offensive sending of emit messages to
	// CompilationState temp data object.
	
	public void emit1(CommonTree opAST, short opcode, int arg) {
		$template::state.emit1(opAST, opcode, arg);
	}
	public void emit1(CommonTree opAST, short opcode, String arg) {
		$template::state.emit1(opAST, opcode, arg);
	}
	public void emit2(CommonTree opAST, short opcode, int arg, int arg2) {
		$template::state.emit2(opAST, opcode, arg, arg2);
	}
	public void emit2(CommonTree opAST, short opcode, String s, int arg2) {
		$template::state.emit2(opAST, opcode, s, arg2);
	}
	public void emit(short opcode) {
		$template::state.emit(opcode);
    }
    public void emit(CommonTree opAST, short opcode) {
		$template::state.emit(opAST, opcode);
	}
	public void insert(int addr, short opcode, String s) {
		$template::state.insert(addr, opcode, s);
	}
	public void setOption(CommonTree id) {
		$template::state.setOption(id);
	}
	public void write(int addr, short value) {
		$template::state.write(addr,value);
	}
	public int address() { return $template::state.ip; }
	public void func(CommonTree id) { $template::state.func(templateToken, id); }
	public void refAttr(CommonTree id) { $template::state.refAttr(templateToken, id); }
}

templateAndEOF : template[null,null] EOF; // hush warning; ignore

template[String name, List<FormalArgument> args] returns [CompiledST impl]
scope {
    CompilationState state; // automatically get a new state pointer per invocation
}
@init {
 	$template::state = new CompilationState(errMgr, name, input.getTokenStream());
	$impl = $template::state.impl;
 	if ( $template.size() == 1 ) outermostImpl = $impl;
	$impl.defineFormalArgs($args); // make sure args are defined prior to compilation
	if ( name!=null && name.startsWith(Compiler.SUBTEMPLATE_PREFIX) ) {
	    $impl.addArg(new FormalArgument("i"));
	    $impl.addArg(new FormalArgument("i0"));
    }
	$impl.template = template;
}
	:	chunk
		{ // finish off the CompiledST result
        if ( $template::state.stringtable!=null ) $impl.strings = $template::state.stringtable.toArray();
        $impl.codeSize = $template::state.ip;
		}
	;

chunk
	:	element*
	;
	
element
	:	^(INDENT {$template::state.indent($INDENT.text);} element {$template::state.emit(Bytecode.INSTR_DEDENT);})
	|	ifstat
	|	exprElement
	|	TEXT
		{
		if ( $TEXT.text.length()>0 ) {
			emit1($TEXT,Bytecode.INSTR_LOAD_STR, $TEXT.text);
			emit($TEXT,Bytecode.INSTR_WRITE);
		}
		}
	|	region
		{
		emit2($region.start, Bytecode.INSTR_NEW, $region.name, 0);
		emit($region.start, Bytecode.INSTR_WRITE);
		}
	|	NEWLINE {emit(Bytecode.INSTR_NEWLINE);}
	;

exprElement
@init { short op = Bytecode.INSTR_WRITE; }
	:	^( EXPR expr (exprOptions {op=Bytecode.INSTR_WRITE_OPT;})? )
		{emit($EXPR, op);}
	;

region returns [String name]
	:	^(	REGION ID
			{$name = STGroup.getMangledRegionName(outermostTemplateName, $ID.text);}
			template[$name,null]
			{
			CompiledST sub = $template.impl;
	        sub.isRegion = true;
	        sub.regionDefType = ST.RegionType.EMBEDDED;
			sub.dump();
			outermostImpl.addImplicitlyDefinedTemplate(sub);
			}
		 )
	;

subtemplate returns [String name, int nargs]
@init {
    $name = Compiler.getNewSubtemplateName();
	List<FormalArgument> args = new ArrayList<FormalArgument>();
}
	:	^(	SUBTEMPLATE
			(^(ARGS (ID {args.add(new FormalArgument($ID.text));})+))*
			{$nargs = args.size();}
			template[$name,args]
			{
			CompiledST sub = $template.impl;
			sub.isAnonSubtemplate = true;
			sub.dump();
			outermostImpl.addImplicitlyDefinedTemplate(sub);
			}
		 )
	;

ifstat
@init {
    /** Tracks address of branch operand (in code block).  It's how
     *  we backpatch forward references when generating code for IFs.
     */
    int prevBranchOperand = -1;
    /** Branch instruction operands that are forward refs to end of IF.
     *  We need to update them once we see the endif.
     */
    List<Integer> endRefs = new ArrayList<Integer>();
}
	:	^(	i='if' conditional
			{
	        prevBranchOperand = address()+1;
	        emit1($i,Bytecode.INSTR_BRF, -1); // write placeholder as branch target
			}
			chunk
			(	^(eif='elseif'
				{
				endRefs.add(address()+1);
				emit1($eif,Bytecode.INSTR_BR, -1); // br end
				// update previous branch instruction
				write(prevBranchOperand, (short)address());
				prevBranchOperand = -1;
				}
				ec=conditional
				{
		       	prevBranchOperand = address()+1;
		       	// write placeholder as branch target
		       	emit1($ec.start, Bytecode.INSTR_BRF, -1);
				}
				chunk
				)
			)*
			(	^(	el='else'
					{
					endRefs.add(address()+1);
					emit1($el, Bytecode.INSTR_BR, -1); // br end
					// update previous branch instruction
					write(prevBranchOperand, (short)address());
					prevBranchOperand = -1;
					}
					chunk
				 )
			)?
		 )
		{
		if ( prevBranchOperand>=0 ) {
			write(prevBranchOperand, (short)address());
		}
        for (int opnd : endRefs) write(opnd, (short)address());
		}
	;

conditional
	:	^('||' conditional conditional)		{emit(Bytecode.INSTR_OR);}
	|	^('&&' conditional conditional)		{emit(Bytecode.INSTR_AND);}
	|	^('!' conditional)					{emit(Bytecode.INSTR_NOT);}
	|	expr // not all expr are valid, but reuse code gen (parser restricts syntax)
	;

exprOptions : {emit(Bytecode.INSTR_OPTIONS);} ^(OPTIONS option*) ;

option : ^('=' ID expr) {setOption($ID);} ;

expr
@init {int nt = 0, ne = 0;}
	:	^(ZIP ^(ELEMENTS (expr {ne++;})+) mapTemplateRef[ne])
		{emit1($ZIP, Bytecode.INSTR_ZIP_MAP, ne);}
	|	^(MAP expr (mapTemplateRef[1] {nt++;})+)
		{
		if ( nt>1 ) emit1($MAP, nt>1?Bytecode.INSTR_ROT_MAP:Bytecode.INSTR_MAP, nt);
		else emit($MAP, Bytecode.INSTR_MAP);
		}
	|	prop
	|	includeExpr
	;

prop:	^(PROP expr ID)						{emit1($PROP, Bytecode.INSTR_LOAD_PROP, $ID.text);}
	|	^(PROP_IND expr expr)				{emit($PROP_IND, Bytecode.INSTR_LOAD_PROP_IND);}
	;
	
mapTemplateRef[int num_exprs]
	:	^(	INCLUDE ID
			{for (int i=1; i<=$num_exprs; i++) emit($INCLUDE,Bytecode.INSTR_NULL);}
			args
		)
		{emit2($INCLUDE, Bytecode.INSTR_NEW, $ID.text, $args.n+$num_exprs);}
	|	subtemplate
		{
		if ( $subtemplate.nargs != $num_exprs ) {
            errMgr.compileTimeError(ErrorType.ANON_ARGUMENT_MISMATCH,
            						templateToken, $subtemplate.start.token, $subtemplate.nargs, $num_exprs);
		}
		for (int i=1; i<=$num_exprs; i++) emit($subtemplate.start,Bytecode.INSTR_NULL);
        emit2($subtemplate.start, Bytecode.INSTR_NEW,
	              $subtemplate.name,
	              $num_exprs);
		}

	|	^(	INCLUDE_IND expr
			{
			emit($INCLUDE_IND,Bytecode.INSTR_TOSTR);
			for (int i=1; i<=$num_exprs; i++) emit($INCLUDE_IND,Bytecode.INSTR_NULL);
			}
			args
			{emit1($INCLUDE_IND, Bytecode.INSTR_NEW_IND, $args.n+$num_exprs);}
		 )
	;

includeExpr
	:	^(EXEC_FUNC ID expr?)		{func($ID);}
	|	^(INCLUDE ID args)			{emit2($start,Bytecode.INSTR_NEW, $ID.text, $args.n);}
	|	^(INCLUDE_SUPER ID args)	{emit2($start,Bytecode.INSTR_SUPER_NEW, $ID.text, $args.n);}
	|	^(INCLUDE_REGION ID)		{
									CompiledST impl =
										Compiler.defineBlankRegion(outermostImpl, $ID.text);
									impl.dump();
									emit2($INCLUDE_REGION,Bytecode.INSTR_NEW,impl.name,0);
									}
	|	^(INCLUDE_SUPER_REGION ID)	{
									CompiledST impl =
										Compiler.defineBlankRegion(outermostImpl, $ID.text);
									impl.dump();
									emit2($INCLUDE_SUPER_REGION,Bytecode.INSTR_SUPER_NEW,impl.name,0);
									}
	|	primary
	;

primary
	:	ID				{refAttr($ID);}
	|	STRING			{emit1($STRING,Bytecode.INSTR_LOAD_STR, Misc.strip($STRING.text,1));}	
	|	subtemplate		// push a subtemplate but ignore args since we can't pass any to it here
		                {emit2($start,Bytecode.INSTR_NEW, $subtemplate.name, 0);}
	|	list
	|	^(	INCLUDE_IND	
			expr 		{emit($INCLUDE_IND, Bytecode.INSTR_TOSTR);}
			args		{emit1($INCLUDE_IND, Bytecode.INSTR_NEW_IND, $args.n);}
		 )
	|	^(TO_STR expr)	{emit($TO_STR, Bytecode.INSTR_TOSTR);}
	;

args returns [int n=0] : ( arg {$n++;} )* ;

arg : expr ;

list:	{emit(Bytecode.INSTR_LIST);}
		^(LIST (listElement {emit($listElement.start, Bytecode.INSTR_ADD);})* ) 
	;

listElement : expr | NULL {emit($NULL,Bytecode.INSTR_NULL);} ;