package AutoVerify::Error;
##############################################################################
# AutoVerify::Error - base of the error hierarchy.
#
# Library code throws these instead of bare die(). Each carries structured
# fields (file/line/column/message/suggestion) but also stringifies to a
# single readable line via overload, so existing CLI code that just prints
# "$@" continues to work unchanged.
##############################################################################
use strict;
use warnings;
use overload '""' => \&to_string, fallback => 1;

sub new {
    my ($class, %args) = @_;
    return bless {
        message    => $args{message}    // 'Unknown error',
        file       => $args{file},
        line       => $args{line},
        column     => $args{column},
        suggestion => $args{suggestion},
    }, $class;
}

sub throw {
    my ($class, %args) = @_;
    die $class->new(%args);
}

sub message    { return $_[0]->{message}; }
sub file       { return $_[0]->{file}; }
sub line       { return $_[0]->{line}; }
sub column     { return $_[0]->{column}; }
sub suggestion { return $_[0]->{suggestion}; }

sub to_string {
    my ($self) = @_;
    my $loc = '';
    if (defined $self->{file}) {
        $loc = $self->{file};
        $loc .= ":$self->{line}"           if defined $self->{line};
        $loc .= ":$self->{column}"         if defined $self->{column};
        $loc = "$loc: ";
    }
    my $s = "${loc}" . ref($self) . ": $self->{message}";
    $s .= "\n  suggestion: $self->{suggestion}" if $self->{suggestion};
    return $s;
}

1;
