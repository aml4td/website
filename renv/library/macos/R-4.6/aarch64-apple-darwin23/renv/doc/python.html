<!DOCTYPE html>

<html>

<head>

<meta charset="utf-8" />
<meta name="generator" content="pandoc" />
<meta http-equiv="X-UA-Compatible" content="IE=EDGE" />

<meta name="viewport" content="width=device-width, initial-scale=1" />



<title>Using Python with renv</title>

<script>// Pandoc 2.9 adds attributes on both header and div. We remove the former (to
// be compatible with the behavior of Pandoc < 2.8).
document.addEventListener('DOMContentLoaded', function(e) {
  var hs = document.querySelectorAll("div.section[class*='level'] > :first-child");
  var i, h, a;
  for (i = 0; i < hs.length; i++) {
    h = hs[i];
    if (!/^h[1-6]$/i.test(h.tagName)) continue;  // it should be a header h1-h6
    a = h.attributes;
    while (a.length > 0) h.removeAttribute(a[0].name);
  }
});
</script>

<style type="text/css">
code{white-space: pre-wrap;}
span.smallcaps{font-variant: small-caps;}
span.underline{text-decoration: underline;}
div.column{display: inline-block; vertical-align: top; width: 50%;}
div.hanging-indent{margin-left: 1.5em; text-indent: -1.5em;}
ul.task-list{list-style: none;}
</style>







<style type="text/css">body {
background-color: #fff;
margin: 1em auto;
max-width: 700px;
overflow: visible;
padding-left: 2em;
padding-right: 2em;
font-family: "Open Sans", "Helvetica Neue", Helvetica, Arial, sans-serif;
font-size: 14px;
line-height: 1.35;
}
#TOC {
clear: both;
margin: 0 0 10px 10px;
padding: 4px;
width: 400px;
border: 1px solid #CCCCCC;
border-radius: 5px;
background-color: #f6f6f6;
font-size: 13px;
line-height: 1.3;
}
#TOC .toctitle {
font-weight: bold;
font-size: 15px;
margin-left: 5px;
}
#TOC ul {
padding-left: 40px;
margin-left: -1.5em;
margin-top: 5px;
margin-bottom: 5px;
}
#TOC ul ul {
margin-left: -2em;
}
#TOC li {
line-height: 16px;
}
table {
margin: 1em auto;
border-width: 1px;
border-color: #DDDDDD;
border-style: outset;
border-collapse: collapse;
}
table th {
border-width: 2px;
padding: 5px;
border-style: inset;
}
table td {
border-width: 1px;
border-style: inset;
line-height: 18px;
padding: 5px 5px;
}
table, table th, table td {
border-left-style: none;
border-right-style: none;
}
table thead, table tr.even {
background-color: #f7f7f7;
}
p {
margin: 0.5em 0;
}
blockquote {
background-color: #f6f6f6;
padding: 0.25em 0.75em;
}
hr {
border-style: solid;
border: none;
border-top: 1px solid #777;
margin: 28px 0;
}
dl {
margin-left: 0;
}
dl dd {
margin-bottom: 13px;
margin-left: 13px;
}
dl dt {
font-weight: bold;
}
ul {
margin-top: 0;
}
ul li {
list-style: circle outside;
}
ul ul {
margin-bottom: 0;
}
pre, code {
background-color: #f7f7f7;
border-radius: 3px;
color: #333;
white-space: pre-wrap; 
}
pre {
border-radius: 3px;
margin: 5px 0px 10px 0px;
padding: 10px;
}
pre:not([class]) {
background-color: #f7f7f7;
}
code {
font-family: Consolas, Monaco, 'Courier New', monospace;
font-size: 85%;
}
p > code, li > code {
padding: 2px 0px;
}
div.figure {
text-align: center;
}
img {
background-color: #FFFFFF;
padding: 2px;
border: 1px solid #DDDDDD;
border-radius: 3px;
border: 1px solid #CCCCCC;
margin: 0 5px;
}
h1 {
margin-top: 0;
font-size: 35px;
line-height: 40px;
}
h2 {
border-bottom: 4px solid #f7f7f7;
padding-top: 10px;
padding-bottom: 2px;
font-size: 145%;
}
h3 {
border-bottom: 2px solid #f7f7f7;
padding-top: 10px;
font-size: 120%;
}
h4 {
border-bottom: 1px solid #f7f7f7;
margin-left: 8px;
font-size: 105%;
}
h5, h6 {
border-bottom: 1px solid #ccc;
font-size: 105%;
}
a {
color: #0033dd;
text-decoration: none;
}
a:hover {
color: #6666ff; }
a:visited {
color: #800080; }
a:visited:hover {
color: #BB00BB; }
a[href^="http:"] {
text-decoration: underline; }
a[href^="https:"] {
text-decoration: underline; }

code > span.kw { color: #555; font-weight: bold; } 
code > span.dt { color: #902000; } 
code > span.dv { color: #40a070; } 
code > span.bn { color: #d14; } 
code > span.fl { color: #d14; } 
code > span.ch { color: #d14; } 
code > span.st { color: #d14; } 
code > span.co { color: #888888; font-style: italic; } 
code > span.ot { color: #007020; } 
code > span.al { color: #ff0000; font-weight: bold; } 
code > span.fu { color: #900; font-weight: bold; } 
code > span.er { color: #a61717; background-color: #e3d2d2; } 
</style>




</head>

<body>




<h1 class="title toc-ignore">Using Python with renv</h1>



<p>If you’re using renv with an R project that also depends on some
Python packages (say, through the <a href="https://rstudio.github.io/reticulate/">reticulate</a> package),
then you may find renv’s Python integration useful.</p>
<div id="activating-python-integration" class="section level2">
<h2>Activating Python integration</h2>
<p>Python integration can be activated on a project-by-project basis.
Use <code>renv::use_python()</code> to tell renv to create and use a
project-local Python environment with your project. If the reticulate
package is installed and active, then renv will use the same version of
Python that reticulate normally would when generating the virtual
environment. Alternatively, you can set the
<code>RETICULATE_PYTHON</code> environment variable to instruct renv to
use a different version of Python.</p>
<p>If you’d rather tell renv to use an existing Python virtual
environment, you can do so by passing the path of that virtual
environment instead – use
<code>renv::use_python(python = &quot;/path/to/python&quot;)</code> and renv will
record and use that Python interpreter with your project. This can also
be used with pre-existing virtual environments and Conda
environments.</p>
</div>
<div id="understanding-python-integration" class="section level2">
<h2>Understanding Python integration</h2>
<p>Once Python integration is active, renv will attempt to manage the
state of your Python virtual environment when <code>snapshot()</code> /
<code>restore()</code> is called. With this, projects that use renv and
Python can ensure that Python dependencies are tracked in addition to R
package dependencies. Note that future restores will require both
<code>renv.lock</code> (for R package dependencies) and
<code>requirements.txt</code> (for Python package dependencies).</p>
<div id="virtual-environments" class="section level3">
<h3>Virtual environments</h3>
<p>When using virtual environments, the following extensions are
provided:</p>
<ul>
<li><p><code>renv::snapshot()</code> calls
<code>pip freeze &gt; requirements.txt</code> to save the set of
installed Python packages;</p></li>
<li><p><code>renv::restore()</code> calls
<code>pip install -r requirements.txt</code> to install the
previously-recorded set of Python packages.</p></li>
</ul>
</div>
<div id="conda-environments" class="section level3">
<h3>Conda environments</h3>
<p>When using Conda environments, the following extensions are
provided:</p>
<ul>
<li><p><code>renv::snapshot()</code> calls
<code>conda env export &gt; environment.yml</code> to save the set of
installed Python packages;</p></li>
<li><p><code>renv::restore()</code> calls
<code>conda env [create/update] --file environment.yml</code> to install
the previously-recorded set of Python packages.</p></li>
</ul>
</div>
</div>



<!-- code folding -->


<!-- dynamically load mathjax for compatibility with self-contained -->
<script>
  (function () {
    var script = document.createElement("script");
    script.type = "text/javascript";
    script.src  = "https://mathjax.rstudio.com/latest/MathJax.js?config=TeX-AMS-MML_HTMLorMML";
    document.getElementsByTagName("head")[0].appendChild(script);
  })();
</script>

</body>
</html>
