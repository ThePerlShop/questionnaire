#!/usr/bin/env perl
use v5.26;
use warnings;
use utf8;
package t::unit::TPS::Questionnaire::Model::Questionnaire;

use Test2::V0 -target => 'TPS::Questionnaire::Model::Questionnaire';
use Test2::Tools::Explain;
use Test2::Tools::Spec;

use FindBin qw($Bin $Script);
use Path::Tiny qw(path);

# Helper method to connect to a new in-memory database and load into it
# SQL from named files. Returns a dbh for the open database.
sub make_database {
    my @files = @_;

    require DBI;
    my $dbh = DBI->connect('dbi:SQLite:dbname=:memory:', undef, undef, {
        AutoCommit => 1,
        RaiseError => 1,
    });

    my $project_root = path($Bin, $Script)->parent(scalar(split /::/, __PACKAGE__));
    for my $filename (@files) {
        my $sqlfile = $project_root->child('sql', $filename);
        # this is horrible, but...
        $dbh->do($_) for split /;/, $sqlfile->slurp;
    }

    return $dbh;
}


tests from_hashref => sub {
    plan(1);

    my $object = $CLASS->from_hashref({
        title => 'Test Questionnaire',
        is_published => 1,
        questions => [
            'What is your name?',
            {
                question_type => 'single_option',
                question_text => 'What is your favourite colour?',
                options => [
                    { option_text => 'Red' },
                    { option_text => 'Blue' },
                    'Yellow',
                    { option_text => 'Green' },
                ],
            },
            {
                question_type => 'multi_option',
                question_text => 'What pets do you own?',
                options => [ qw(Dog Cat Fish Other) ],
            },
        ],
    });

    is(
        $object,
        (object {
            prop 'isa' => 'TPS::Questionnaire::Model::Questionnaire';
            call 'title' => string 'Test Questionnaire';
            call 'is_published' => bool !!1;
            call 'questions' => array {
                item object {
                    prop 'isa' => 'TPS::Questionnaire::Model::Question::Text';
                    call 'question_text' => 'What is your name?';
                };
                item object {
                    prop 'isa' => 'TPS::Questionnaire::Model::Question::SingleOption';
                    call 'question_text' => 'What is your favourite colour?';
                    call 'options' => array {
                        item object { call 'option_text' => 'Red'; };
                        item object { call 'option_text' => 'Blue'; };
                        item object { call 'option_text' => 'Yellow'; };
                        item object { call 'option_text' => 'Green'; };
                        end();
                    };
                };
                item object {
                    prop 'isa' => 'TPS::Questionnaire::Model::Question::MultiOption';
                    call 'question_text' => 'What pets do you own?';
                    call 'options' => array {
                        item object { call 'option_text' => 'Dog'; };
                        item object { call 'option_text' => 'Cat'; };
                        item object { call 'option_text' => 'Fish'; };
                        item object { call 'option_text' => 'Other'; };
                        end();
                    };
                };
                end();
            };
        }),
        'Correct object created from hashref',
    ) or diag explain($object);
};

tests from_id => sub {
    plan(1);

    require TPS::Questionnaire::Schema;
    my $schema = TPS::Questionnaire::Schema->connect(
        sub { make_database('schema.sql', 'sample-data.sql') },
    );

    my $object = $CLASS->from_id($schema, 1);

    is(
        $object,
        (object {
            prop 'isa' => 'TPS::Questionnaire::Model::Questionnaire';
            call 'title' => string 'Sample Questionnaire';
            call 'is_published' => bool !!1;
            call 'questions' => array {
                item object {
                    prop 'isa' => 'TPS::Questionnaire::Model::Question::Text';
                    call 'question_text' => 'What is your name?';
                };
                item object {
                    prop 'isa' => 'TPS::Questionnaire::Model::Question::Text';
                    call 'question_text' => 'What is your age?';
                };
                item object {
                    prop 'isa' => 'TPS::Questionnaire::Model::Question::SingleOption';
                    call 'question_text' => 'What is your favourite colour?';
                    call 'options' => array {
                        item object { call 'option_text' => 'Red'; };
                        item object { call 'option_text' => 'Blue'; };
                        item object { call 'option_text' => 'Yellow'; };
                        item object { call 'option_text' => 'Green'; };
                        end();
                    };
                };
                item object {
                    prop 'isa' => 'TPS::Questionnaire::Model::Question::MultiOption';
                    call 'question_text' => 'Do you own any pets?';
                    call 'options' => array {
                        item object { call 'option_text' => 'Dog'; };
                        item object { call 'option_text' => 'Cat'; };
                        item object { call 'option_text' => 'Fish'; };
                        item object { call 'option_text' => 'Other'; };
                        end();
                    };
                };
                end();
            };
        }),
        'Correct object created from hashref',
    ) or diag explain($object);
};

tests summary_list => sub {
    plan(1);

    require TPS::Questionnaire::Schema;
    my $schema = TPS::Questionnaire::Schema->connect(
        sub { make_database('schema.sql', 'sample-data.sql') },
    );

    my $summary = $CLASS->summary_list($schema);
    is(
        $summary,
        [ { title => 'Sample Questionnaire', id => 1 } ],
        'summary_list works',
    );
};

tests save => sub {
    plan(1);

    my $object = $CLASS->from_hashref({
        title => 'Test Questionnaire',
        is_published => 1,
        questions => [
            'What is your name?',
            {
                question_type => 'single_option',
                question_text => 'What is your favourite colour?',
                options => [
                    { option_text => 'Red' },
                    { option_text => 'Blue' },
                    'Yellow',
                    { option_text => 'Green' },
                ],
            },
            {
                question_type => 'multi_option',
                question_text => 'What pets do you own?',
                options => [ qw(Dog Cat Fish Other) ],
            },
        ],
    });

    require TPS::Questionnaire::Schema;
    my $schema = TPS::Questionnaire::Schema->connect(
        sub { make_database('schema.sql') },
    );

    # Save and reload from database
    my $id = $object->save($schema);
    $object = $CLASS->from_id($schema, $id);

    is(
        $object,
        object {
            prop 'isa' => 'TPS::Questionnaire::Model::Questionnaire';
            call 'title' => string 'Test Questionnaire';
            call 'is_published' => bool !!1;
            call 'questions' => array {
                item object {
                    prop 'isa' => 'TPS::Questionnaire::Model::Question::Text';
                    call 'question_text' => 'What is your name?';
                };
                item object {
                    prop 'isa' => 'TPS::Questionnaire::Model::Question::SingleOption';
                    call 'question_text' => 'What is your favourite colour?';
                    call 'options' => array {
                        item object { call 'option_text' => 'Red'; };
                        item object { call 'option_text' => 'Blue'; };
                        item object { call 'option_text' => 'Yellow'; };
                        item object { call 'option_text' => 'Green'; };
                        end();
                    };
                };
                item object {
                    prop 'isa' => 'TPS::Questionnaire::Model::Question::MultiOption';
                    call 'question_text' => 'What pets do you own?';
                    call 'options' => array {
                        item object { call 'option_text' => 'Dog'; };
                        item object { call 'option_text' => 'Cat'; };
                        item object { call 'option_text' => 'Fish'; };
                        item object { call 'option_text' => 'Other'; };
                        end();
                    };
                };
                end();
            };
        },
            'Correct object loaded from database',
    ) or diag explain($object);
};


=begin comment

Step 1.
Manual test plan using POSTMAN:
  do a GET to know active Q's.
  do a PUT w/o ID to create new record:

```
{
    "title": "Steve Test PUT without id",
    "is_published": false,
    "questions": [
        {
            "question_type": "text",
            "question_text": "New question here, does not have an id."
        }
    ]
}
```

get a 200 status ok

Step 2.
In Pycharm (or other database tool) verify that the new Q was created. Since we are NOT dealing with
questions in the PUT, their presence in the submitted data is optional. We could use POST to create a
new Q (that would include the questions), being sure to set the is_published to 'false'. But, the
result does not include the QID, so there's no real difference.

Step 3.
Back to POSTMAN, update the url to include the QID created above.
  do a PUT w/ID to update the record with:

```
{
    "title": "Steve Test PUT with id",
    "is_published": true,
}
```

get a 200 status ok

verify in database that the id_published changes from false to true (0 to 1).
verify with GET that the Q is listed.

Step 4.
Back to POSTMAN, send the same data to the same URL as in Step 3.

get a 400 status error

This verifies that the PUT will not update a published Questionnaire.
end.

=end comment

=cut

## updated: 21 Oct 2021 by SJS
## comment: first pass at testing the put method. Need to save hash, but then find the QID, not from GET.
##

tests update => sub {
    plan(2);

    my $object = $CLASS->from_hashref({
        title        => 'Steve Test',
        is_published => 0,
        questions    => [
            {
                question_type => 'text',
                question_text => 'New Question without id.'
            }
        ],
    });

    require TPS::Questionnaire::Schema;
    my $schema = TPS::Questionnaire::Schema->connect(
        sub { make_database('schema.sql') },
    );

    # Save and reload from database
    my $id = $object->save($schema);
    $object = $CLASS->from_id($schema, $id);

    is(
        $object,
        object {
            prop 'isa' => 'TPS::Questionnaire::Model::Questionnaire';
            call 'title' => string 'Steve Test';
            call 'is_published' => bool !!0;
            call 'questions' => array {
                item object {
                    prop 'isa' => 'TPS::Questionnaire::Model::Question::Text';
                    call 'question_text' => 'New Question without id.';
                };

                end();
            };
        },
            'Correct object loaded from database',
    ) or diag explain($object);

    # update the saved object
    #
    $object->is_published( 1 );
    my $up_id = $object->update($schema);
    $object = $CLASS->from_id($schema, $up_id);

    is(
        $object,
        object {
            prop 'isa' => 'TPS::Questionnaire::Model::Questionnaire';
            call 'title' => string 'Steve Test';
            call 'is_published' => bool !!1;
            call 'questions' => array {
                item object {
                    prop 'isa' => 'TPS::Questionnaire::Model::Question::Text';
                    call 'question_text' => 'New Question without id.';
                };

                end();
            };
        },
        'Updated the object properly',
    )
    or diag explain($object);
};





done_testing();

1;
