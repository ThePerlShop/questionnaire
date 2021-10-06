use utf8;
package My::App::Schema::Result::QuestionAnswer;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

My::App::Schema::Result::QuestionAnswer

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 TABLE: C<question_answer>

=cut

__PACKAGE__->table("question_answer");

=head1 ACCESSORS

=head2 question_answer_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 questionnaire_answer_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 question_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 answer_text

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "question_answer_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "questionnaire_answer_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "question_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "answer_text",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</question_answer_id>

=back

=cut

__PACKAGE__->set_primary_key("question_answer_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<questionnaire_answer_id_question_id_unique>

=over 4

=item * L</questionnaire_answer_id>

=item * L</question_id>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "questionnaire_answer_id_question_id_unique",
  ["questionnaire_answer_id", "question_id"],
);

=head1 RELATIONS

=head2 question

Type: belongs_to

Related object: L<My::App::Schema::Result::Question>

=cut

__PACKAGE__->belongs_to(
  "question",
  "My::App::Schema::Result::Question",
  { question_id => "question_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 question_answer_options

Type: has_many

Related object: L<My::App::Schema::Result::QuestionAnswerOption>

=cut

__PACKAGE__->has_many(
  "question_answer_options",
  "My::App::Schema::Result::QuestionAnswerOption",
  { "foreign.question_answer_id" => "self.question_answer_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 questionnaire_answer

Type: belongs_to

Related object: L<My::App::Schema::Result::QuestionnaireAnswer>

=cut

__PACKAGE__->belongs_to(
  "questionnaire_answer",
  "My::App::Schema::Result::QuestionnaireAnswer",
  { questionnaire_answer_id => "questionnaire_answer_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 options

Type: many_to_many

Composing rels: L</question_answer_options> -> option

=cut

__PACKAGE__->many_to_many("options", "question_answer_options", "option");


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2021-10-06 19:30:04
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Yd2tN4TvAS6jT1q1a9wVmw
# These lines were loaded from '/home/tai/perl5/perlbrew/perls/perl-5.34.0/lib/site_perl/5.34.0/My/App/Schema/Result/QuestionAnswer.pm' found in @INC.
# They are now part of the custom portion of this file
# for you to hand-edit.  If you do not either delete
# this section or remove that file from @INC, this section
# will be repeated redundantly when you re-create this
# file again via Loader!  See skip_load_external to disable
# this feature.

use utf8;
package My::App::Schema::Result::QuestionAnswer;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

My::App::Schema::Result::QuestionAnswer

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 TABLE: C<question_answer>

=cut

__PACKAGE__->table("question_answer");

=head1 ACCESSORS

=head2 question_answer_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 questionnaire_answer_id

  data_type: 'integer'
  is_nullable: 1

=head2 question_id

  data_type: 'integer'
  is_nullable: 1

=head2 answer_text

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "question_answer_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "questionnaire_answer_id",
  { data_type => "integer", is_nullable => 1 },
  "question_id",
  { data_type => "integer", is_nullable => 1 },
  "answer_text",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</question_answer_id>

=back

=cut

__PACKAGE__->set_primary_key("question_answer_id");


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2021-10-06 15:05:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:EllQOedM7WqBVr0b+ABezQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
# End of lines loaded from '/home/tai/perl5/perlbrew/perls/perl-5.34.0/lib/site_perl/5.34.0/My/App/Schema/Result/QuestionAnswer.pm'


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
