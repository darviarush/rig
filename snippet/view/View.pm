package Astrobook::Libra::Pages::View;
# Страница книги

use common::sense;
use Aion::View;

# Идентификатор автора
has author_id => (is => "ro", in => 1, isa => Maybe[Nat]);

# Имя автора
has author_name => (is => "ro", in => 1, isa => Maybe[Str]);

# Номер страницы в томе
has book_id => (is => "ro", in => 1, isa => Maybe[Nat]);

# Название книги
has title => (is => "ro", in => 1, isa => Maybe[Str]);

# Текст страницы
has page => (is => "ro", in => 1, isa => Maybe[Str]);

# Номер главы в томе
has chapter => (is => "ro", in => 1, isa => Maybe[Int]);

# Номер страницы в томе
has number => (is => "ro", in => 1, isa => Maybe[Int]);

1;

__DATA__
<article applet=book-pages data-id={{book_id}}>
	<section class="post clearfix">

		{{? number == 1 }}
		<center>

			{{?author_name}}
				<p><a href="/creativity/{{author_id}}" target=_blank>{{author_name}}</a></p>
			{{/?author_name}}
			{{?title}}
				<h2>{{title}}</h2>
			{{/?title}}

		</center>
		{{/? number }}

		<div class="book-pages-page text">{{page!}}</div>

		<p/>
		<center>
			{{number}} ✦ {{&rim(chapter)}}
		</center>
	</section>
</article>
<script>applet($("article[applet=book-pages]:last"))</script>
<!-- page of book -->

@@ meta

<style>
.book-pages-page {
	font-family: Roboto,Helvetica,Arial,sans-serif;
	font-size: 18px;
	line-height: 1.35em;
}
</style>