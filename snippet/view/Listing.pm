package {{pkg}}::Listing;
# Текст книги

use common::sense;
use Aion::View;
use Shop::Common::Head;
use Shop::Product::View;

# Товар
has product => (is => "ro", isa => Maybe[Model['Shop::Product::View']], in => "path");


# Метод GET /libra/{book_id}/pages “Читать книгу”
sub get {
	my ($self) = @_;

	Astrobook::Common::Head->new(
		title => "Товар ${ \ $self->product->name }",
		meta => Astrobook::Libra::Pages::View->meta . Astrobook::Libra::View->meta,
		content => $self->view_listing(pages => \@pages, next_href => $next_href),
		sidebars => [
			Astrobook::Libra::View->new(%$book, is_side => 1, type_page => 'pages')->preview,
			$self->sidebar_table_of_contents,
		],
	)->render;
}

1;
__DATA__

@@ view_listing

{{*page = pages}}
	{{ page.render! }}
{{/*page}}

<center>
	{{?next_href}}
		<a href="{{next_href}}" class="button xs green">Дальше <i class="fa fa-arrow-circle-right" aria-hidden="true"></i></a>
	{{/?next_href}}
	{{?!next_href}}
		<a href="/similis/libro/{{book_id}}?asc" class="button xs green">Конец</a>
	{{/?next_href}}
</center>


@@ sidebar_table_of_contents

<style>
.toc-chapters li[active] a:link,
.toc-chapters li[active] a:visited,
.toc-chapters li[active] a:active
	{ color: Crimson }

.toc-chapters { overflow: hidden }

.toc-title {
	cursor: pointer;
}
.toc-button {
	float: right
}
</style>

<section applet=toc class="widget clearfix">
	<h4 class="toc-title widgettitle">
		Содержание
		<span class="toc-button"><i class="fa fa-caret-up" aria-hidden="true"></i></span>
	</h4>
	<ul class="toc-chapters">
		{{*chapter = chapters}}
			<li {{chapter:book_id == book_id ? active}}><a href="/libra/{{chapter:book_id}}/pages">{{&rim(chapter:chapter)}}. {{chapter:title}}</a>
		{{/*chapter}}
	</ul>
</section>