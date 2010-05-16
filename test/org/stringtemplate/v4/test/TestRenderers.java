/*
 [The "BSD licence"]
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
package org.stringtemplate.v4.test;

import org.junit.Test;
import static org.junit.Assert.assertEquals;

import java.util.*;

public class TestRenderers extends BaseTest {
    @Test public void testRendererForGroup() throws Exception {
        String templates =
                "dateThing(created) ::= \"datetime: <created>\"\n";
        writeFile(tmpdir, "t.stg", templates);
        org.stringtemplate.v4.STGroup group = new org.stringtemplate.v4.STGroupFile(tmpdir+"/t.stg");
        group.registerRenderer(GregorianCalendar.class, new org.stringtemplate.v4.DateRenderer());
        org.stringtemplate.v4.ST st = group.getInstanceOf("dateThing");
        st.add("created", new GregorianCalendar(2005, 07-1, 05));
        String expecting = "datetime: 7/5/05 12:00 AM";
        String result = st.render();
        assertEquals(expecting, result);
    }

    @Test public void testRendererWithFormat() throws Exception {
        String templates =
                "dateThing(created) ::= << date: <created; format=\"yyyy.MM.dd\"> >>\n";
        writeFile(tmpdir, "t.stg", templates);
        org.stringtemplate.v4.STGroup group = new org.stringtemplate.v4.STGroupFile(tmpdir+"/t.stg");
        group.registerRenderer(GregorianCalendar.class, new org.stringtemplate.v4.DateRenderer());
        org.stringtemplate.v4.ST st = group.getInstanceOf("dateThing");
        st.add("created", new GregorianCalendar(2005, 07-1, 05));
        String expecting = " date: 2005.07.05 ";
        String result = st.render();
        assertEquals(expecting, result);
    }

    @Test public void testRendererWithPredefinedFormat() throws Exception {
        String templates =
                "dateThing(created) ::= << datetime: <created; format=\"short\"> >>\n";
        writeFile(tmpdir, "t.stg", templates);
        org.stringtemplate.v4.STGroup group = new org.stringtemplate.v4.STGroupFile(tmpdir+"/t.stg");
        group.registerRenderer(GregorianCalendar.class, new org.stringtemplate.v4.DateRenderer());
        org.stringtemplate.v4.ST st = group.getInstanceOf("dateThing");
        st.add("created", new GregorianCalendar(2005, 07-1, 05));
        String expecting = " datetime: 7/5/05 12:00 AM ";
        String result = st.render();
        assertEquals(expecting, result);
    }

    @Test public void testRendererWithPredefinedFormat2() throws Exception {
        String templates =
                "dateThing(created) ::= << datetime: <created; format=\"full\"> >>\n";
        writeFile(tmpdir, "t.stg", templates);
        org.stringtemplate.v4.STGroup group = new org.stringtemplate.v4.STGroupFile(tmpdir+"/t.stg");
        group.registerRenderer(GregorianCalendar.class, new org.stringtemplate.v4.DateRenderer());
        org.stringtemplate.v4.ST st = group.getInstanceOf("dateThing");
        st.add("created", new GregorianCalendar(2005, 07-1, 05));
        String expecting = " datetime: Tuesday, July 5, 2005 12:00:00 AM PDT ";
        String result = st.render();
        assertEquals(expecting, result);
    }

    @Test public void testRendererWithPredefinedFormat3() throws Exception {
        String templates =
                "dateThing(created) ::= << date: <created; format=\"date:medium\"> >>\n";

        writeFile(tmpdir, "t.stg", templates);
        org.stringtemplate.v4.STGroup group = new org.stringtemplate.v4.STGroupFile(tmpdir+"/t.stg");
        group.registerRenderer(GregorianCalendar.class, new org.stringtemplate.v4.DateRenderer());
        org.stringtemplate.v4.ST st = group.getInstanceOf("dateThing");
        st.add("created", new GregorianCalendar(2005, 07-1, 05));
        String expecting = " date: Jul 5, 2005 ";
        String result = st.render();
        assertEquals(expecting, result);
    }

    @Test public void testRendererWithPredefinedFormat4() throws Exception {
        String templates =
                "dateThing(created) ::= << time: <created; format=\"time:medium\"> >>\n";

        writeFile(tmpdir, "t.stg", templates);
        org.stringtemplate.v4.STGroup group = new org.stringtemplate.v4.STGroupFile(tmpdir+"/t.stg");
        group.registerRenderer(GregorianCalendar.class, new org.stringtemplate.v4.DateRenderer());
        org.stringtemplate.v4.ST st = group.getInstanceOf("dateThing");
        st.add("created", new GregorianCalendar(2005, 07-1, 05));
        String expecting = " time: 12:00:00 AM ";
        String result = st.render();
        assertEquals(expecting, result);
    }

    @Test public void testStringRendererWithPrintfFormat() throws Exception {
        String templates =
                "foo(x) ::= << <x; format=\"%6s\"> >>\n";

        writeFile(tmpdir, "t.stg", templates);
        org.stringtemplate.v4.STGroup group = new org.stringtemplate.v4.STGroupFile(tmpdir+"/t.stg");
        group.registerRenderer(String.class, new org.stringtemplate.v4.StringRenderer());
        org.stringtemplate.v4.ST st = group.getInstanceOf("foo");
        st.add("x", "hi");
        String expecting = "     hi ";
        String result = st.render();
        assertEquals(expecting, result);
    }

    @Test public void testNumberRendererWithPrintfFormat() throws Exception {
        String templates =
                "foo(x,y) ::= << <x; format=\"%d\"> <y; format=\"%2.3f\"> >>\n";

        writeFile(tmpdir, "t.stg", templates);
        org.stringtemplate.v4.STGroup group = new org.stringtemplate.v4.STGroupFile(tmpdir+"/t.stg");
        group.registerRenderer(Integer.class, new org.stringtemplate.v4.NumberRenderer());
        group.registerRenderer(Double.class, new org.stringtemplate.v4.NumberRenderer());
        org.stringtemplate.v4.ST st = group.getInstanceOf("foo");
        st.add("x", -2100);
        st.add("y", 3.14159);
        String expecting = " -2100 3.142 ";
        String result = st.render();
        assertEquals(expecting, result);
    }

    @Test public void testLocaleWithNumberRenderer() throws Exception {
        String templates =
                "foo(x,y) ::= << <x; format=\"%,d\"> <y; format=\"%,2.3f\"> >>\n";

        writeFile(tmpdir, "t.stg", templates);
        org.stringtemplate.v4.STGroup group = new org.stringtemplate.v4.STGroupFile(tmpdir+"/t.stg");
        group.registerRenderer(Integer.class, new org.stringtemplate.v4.NumberRenderer());
        group.registerRenderer(Double.class, new org.stringtemplate.v4.NumberRenderer());
        org.stringtemplate.v4.ST st = group.getInstanceOf("foo");
        st.add("x", -2100);
        st.add("y", 3.14159);
        // Polish uses ' ' for ',' and ',' for '.'
        String expecting = " -2�100 3,142 ";
        String result = st.render(new Locale("pl"));
        assertEquals(expecting, result);
    }

    @Test public void testRendererWithFormatAndList() throws Exception {
        String template =
                "The names: <names; format=\"upper\">";
        org.stringtemplate.v4.STGroup group = new org.stringtemplate.v4.STGroup();
        group.registerRenderer(String.class, new org.stringtemplate.v4.StringRenderer());
        org.stringtemplate.v4.ST st = new org.stringtemplate.v4.ST(template);
        st.groupThatCreatedThisInstance = group;
        st.add("names", "ter");
        st.add("names", "tom");
        st.add("names", "sriram");
        String expecting = "The names: TERTOMSRIRAM";
        String result = st.render();
        assertEquals(expecting, result);
    }

    @Test public void testRendererWithFormatAndSeparator() throws Exception {
        String template =
                "The names: <names; separator=\" and \", format=\"upper\">";
        org.stringtemplate.v4.STGroup group = new org.stringtemplate.v4.STGroup();
        group.registerRenderer(String.class, new org.stringtemplate.v4.StringRenderer());
        org.stringtemplate.v4.ST st = new org.stringtemplate.v4.ST(template);
        st.groupThatCreatedThisInstance = group;
        st.add("names", "ter");
        st.add("names", "tom");
        st.add("names", "sriram");
        String expecting = "The names: TER and TOM and SRIRAM";
        String result = st.render();
        assertEquals(expecting, result);
    }

    @Test public void testRendererWithFormatAndSeparatorAndNull() throws Exception {
        String template =
                "The names: <names; separator=\" and \", null=\"n/a\", format=\"upper\">";
        org.stringtemplate.v4.STGroup group = new org.stringtemplate.v4.STGroup();
        group.registerRenderer(String.class, new org.stringtemplate.v4.StringRenderer());
        org.stringtemplate.v4.ST st = new org.stringtemplate.v4.ST(template);
        st.groupThatCreatedThisInstance = group;
        List names = new ArrayList();
        names.add("ter");
        names.add(null);
        names.add("sriram");
        st.add("names", names);
        String expecting = "The names: TER and N/A and SRIRAM";
        String result = st.render();
        assertEquals(expecting, result);
    }
    
}