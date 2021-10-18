#!/usr/bin/env perl
use v5.26;
use warnings;
use utf8;

use Test2::V0;
use Test2::Tools::Explain;

use HTTP::Request::Common;
use JSON::PP qw(decode_json encode_json);
use Path::Tiny qw(tempfile);

# The following all happens before Catalyst::Test loads the system under test.
BEGIN {
    # This causes Catalyst::Plugin::ConfigLoader to load my_app_test.conf
    # instead of my_app_local.conf.
    $ENV{TPS_QUESTIONNAIRE_CONFIG_LOCAL_SUFFIX} = 'test';

    my $database_file = tempfile();
    # MY_APP_TEST_DATABASE is used by my_app_test.conf to find the SQLite database file.
    $ENV{TPS_QUESTIONNAIRE_TEST_DATABASE} = "$database_file";

    # Turn off Catalyst debug output, please.
    $ENV{TPS_QUESTIONNAIRE_DEBUG} = 0;
}
use Catalyst::Test 'TPS::Questionnaire';

confirm_no_initial_questionnaires();
post_new_questionnaire();
publish_unpublished_questionnaire();

done_testing();

sub confirm_no_initial_questionnaires {
    is(
        decode_json(request('/api/questionnaire')->decoded_content),
        {
            result => { count => 0, list => [] },
            status => 'ok',
        },
        'GET /api/questionnaire -> ok',
    );
    
    # And thus, cannot GET id 1
    is(
        request('/api/questionnaire/1')->code,
        404,
        'GET /api/questionnaire/1 -> 404',
    );
}


sub post_new_questionnaire {
    is(
        request(
            POST '/api/questionnaire',
                Content_Type => 'application/json',
                Content => encode_json({
                    title => 'Sample Questionnaire',
                    is_published => \1,
                    questions => [ 'Foo?', 'Bar?' ]
                })
        )->code,
        200,
        'POST /api/questionnaire -> ok',
    );
    
    is(
        decode_json(request('/api/questionnaire')->decoded_content),
        {
            result => { count => 1, list => [
                { id => 1, title => 'Sample Questionnaire' },
            ] },
            status => 'ok',
        },
        'GET /api/questionnaire -> ok',
    );
}

sub publish_unpublished_questionnaire {
    is(
        request(
            POST '/api/questionnaire',
            Content_Type => 'application/json',
            Content => encode_json({
                title => 'New Questionnaire',
                is_published => \0,
                questions => [ 'When?', 'Why?' ]
            })
        )->code,
        200,
        'POST /api/questionnaire (unpublished) - ok'
    );
 
    # Cannot see it when unpublished:
    is(
        decode_json(request('/api/questionnaire')->decoded_content),
        {
            result => { count => 1, list => [
                { id => 1, title => 'Sample Questionnaire' },
            ] },
            status => 'ok',
        },
        'Still only one questionnaire displayed'
    );

    is(
        request(PUT '/api/questionnaire/2', Content_Type => 'application/json')->code,
        200,
        'PUT /api/questionnaire -> ok (published!)'
    );

    my $r = request('/api/questionnaire');

    is(
        decode_json(request('/api/questionnaire')->decoded_content)->{result}{count},
        2,
        'Second questionnaire displayed'
    );

}
