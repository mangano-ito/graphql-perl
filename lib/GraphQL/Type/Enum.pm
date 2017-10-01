package GraphQL::Type::Enum;

use 5.014;
use strict;
use warnings;
use Moo;
use Types::Standard -all;
use GraphQL::Type::Library -all;
use GraphQL::Debug qw(_debug);
use Function::Parameters;
use Return::Type;
extends qw(GraphQL::Type);
with qw(
  GraphQL::Role::Input
  GraphQL::Role::Output
  GraphQL::Role::Leaf
  GraphQL::Role::Nullable
  GraphQL::Role::Named
  GraphQL::Role::FieldDeprecation
);

our $VERSION = '0.02';

use constant DEBUG => $ENV{GRAPHQL_DEBUG};

=head1 NAME

GraphQL::Type::Enum - GraphQL enum type

=head1 SYNOPSIS

  use GraphQL::Type::Enum;
  my %text2value;
  my $type = GraphQL::Type::Enum->new(
    name => 'Enum',
    values => { value1 => {}, value2 => { value => 'yo' } },
  );

=head1 ATTRIBUTES

Has C<name>, C<description> from L<GraphQL::Role::Named>.

=head2 values

Hash-ref mapping value labels to a hash-ref description. Description keys,
all optional:

=over

=item value

Perl value of that  item. If not specified, will be the string name of
the value. Integers are often useful.

=item deprecation_reason

Reason if deprecated. If supplied, the hash for that value will also
have a key C<is_deprecated> with a true value.

=item description

Description.

=back

=cut

has values => (
  is => 'ro',
  isa => Map[
    StrNameValid,
    Dict[
      value => Optional[Any],
      deprecation_reason => Optional[Str],
      description => Optional[Str],
    ]
  ],
  required => 1,
);

=head1 METHODS

=head2 is_valid

True if given Perl entity is valid value for this type. Relies on unique
stringification of the value.

=cut

has _name2value => (is => 'lazy', isa => Map[StrNameValid, Any]);
sub _build__name2value {
  my ($self) = @_;
  my $v = $self->values;
  +{ map { ($_ => $v->{$_}{value}) } keys %$v };
}

has _value2name => (is => 'lazy', isa => Map[Str, StrNameValid]);
sub _build__value2name {
  my ($self) = @_;
  my $n2v = $self->_name2value;
  DEBUG and _debug('_build__value2name', $self, $n2v);
  +{ reverse %$n2v };
}

method is_valid(Any $item) :ReturnType(Bool) {
  DEBUG and _debug('is_valid', $item, $item.'', $self->_value2name);
  return 1 if !defined $item;
  !!$self->_value2name->{$item};
}

method graphql_to_perl(Any $item) {
  DEBUG and _debug('graphql_to_perl', $item, $self->_value2name);
  return undef if !defined $item;
  $self->_name2value->{$item};
}

=head2 BUILD

Internal method.

=cut

sub BUILD {
  my ($self, $args) = @_;
  $self->_fields_deprecation_apply('values');
  my $v = $self->values;
  for my $name (keys %$v) {
    $v->{$name}{value} = $name if !exists $v->{$name}{value}; # undef valid
  }
}

__PACKAGE__->meta->make_immutable();

1;
