$bibtex_use = 2;            # clean up biber files when -c (and rerun @ compilation)
$do_cd = 1;                 # relative path compilation (needed for icloud)
$clean_ext = "nav snm";
$pdf_previewer = 'open -a Skim';
$pdflatex = 'lualatex --shell-escape'
#$pdflatex = 'xelatex'
#$pdflatex = 'pdflatex -synctex=1 -interaction=nonstopmode --extra-mem-bot=120000000'
