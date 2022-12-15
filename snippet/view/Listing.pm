package {{pkg}}::Listing;
# Текст книги

use common::sense;
use Aion::View;
use Astrobook::Common::Head;
use Astrobook::Libra::Pages::View;
use Astrobook::Libra::View;

# Идентификатор книги в томе
has book_id => (is => "ro", isa => Maybe[Nat], in => "path");

# Тело книги
has book => (is => "ro", isa => Maybe[Str], in => "data", coerce => EmptyStrToUndef);

# Содержание
has chapters => (is => 'ro', isa => ArrayRef, default => sub {
	my ($self) = @_;
	query_ref "SELECT
		id as book_id,
		chapter,
		title
	FROM book
	WHERE tom_id=(SELECT tom_id FROM book WHERE id=:book_id)
	ORDER BY chapter", book_id => $self->book_id;
});



# Метод PUT /libra/{book_id}/pages “Редактировать книгу” с авторизацией
sub put {
	my ($self) = @_;

	my $book = query_row "SELECT
		tom_id,
		user.id as user_id
	FROM book
	INNER JOIN author ON author.id=book.author_id
	LEFT JOIN user ON user.author_id=author.id
	WHERE id=:book_id", book_id => $self->book_id;

	die Aion::Response->not_found("Книга не найдена.") if !$book;
	die Aion::Response->forbidden("Доступ запрещён.") if !defined($book->{user_id}) || $book->{user_id} != is_auth();

	# Тут book уже с <PAGE/> или нет?
	update book => $self->book_id, book => to_book $self->book;

	return {
		id => $self->book_id,
	}
}

# Метод GET /libra/{book_id}/pages “Читать книгу”
sub get {
	my ($self) = @_;

	my $book = query_row "SELECT ${\ Astrobook::Libra::View->selectors },
		book.chapter,
		book.book
	FROM book
	LEFT JOIN author ON author.id=book.author_id
	WHERE book.id=:book_id",
		book_id => $self->book_id,
	;

	return Aion::Response->not_found("Книга не найдена.") if !$book;

	if( !$book->{tom_id} ) {
		my $book_id = query_scalar "SELECT id FROM book WHERE tom_id=:tom_id ORDER BY chapter LIMIT 1", tom_id => $self->book_id;
		return Aion::Response->bad_request("У тома нет глав.") if !defined $book_id;
		return Aion::Response->redirect("/libra/$book_id/pages");
	}

	my @x = split m!<PAGE/>!, $book->{book};

	# Бъём текст на страницы по размеру
	my $i = 1;
	my @pages = map Astrobook::Libra::Pages::View->new(%$book, page => $_, number => $i++),
		@x;

	my ($next) = grep $_->{chapter} > $book->{chapter}, @{$self->chapters};

	my $next_href = $next? "/libra/$next->{book_id}/pages": "";

	Astrobook::Common::Head->new(
		title => "Чтение $book->{author_name} «$book->{title}»",
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