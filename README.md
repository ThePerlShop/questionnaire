# questionnaire

The purpose of this project is to provide a REST API through which users
can access questionnaires and answer the questions therein.

Each questionnaire consists of a series of 0 or more questions.

Each question has a question type, as follows:

- `text` - answered in freeform text
- `single_option` - answered by choosing a single option from a list
- `multi_option` - answered by choosing zero or more options from a list

The available questionnaires and user answers are stored in an SQLite
database. (A sample database is provided as `questionnaire.sqlite` in
the repository.)

## Development install and test

This project requires Perl v5.26; however, it should work with newer
versions as well.

We recommend creating a `perlbrew` or `plenv` environment, using an
environment-specific `local::lib`, in which to do development.

All dependent modules can be installed into the dev environment from the
included `cpanfile`, using `cpanm` from the project root directory:

    cpanm --installdeps .

### Running tests

You can run the test suite from the project root directory with

    prove -lrm t/

…or…

    yath t/

### Running the development server

Run `script/questionnaire_server.pl` to test the application.

## API

All responses are JSON. All POST bodies are JSON unless otherwise noted.

### The questionnaire object

The following structure is known as a "questionnaire object" and is used
in various places in this API. It describes a questionnaire and its
questions.

    {
        "id": 1,
        "title": "Questionnaire One",
        "is_published": true,
        "questions": [
            {
                "id": 1,
                "question_type": "text",
                "question_text": "What is your name?"
            },
            {
                "id": 2,
                "question_type": "single_option",
                "question_text": "What is your favourite colour?",
                "options": [
                    { "id": 1, "option_text": "Red" },
                    { "id": 2, "option_text": "Blue" },
                    { "id": 3, "option_text": "Yellow" },
                    { "id": 4, "option_text": "Green" }
                ]
            },
            {
                "id": 3,
                "question_type": "multi_option",
                "question_text": "Do you have a pet?",
                "options": [
                    { "id": 5, "option_text": "Dog" },
                    { "id": 6, "option_text": "Cat" },
                    { "id": 7, "option_text": "Rabbit" },
                    { "id": 8, "option_text": "Other" }
                ]
            }
        ]
    }

### POST /api/questionnaire

Creates a new questionnaire.

POST a questionnaire object as JSON (without any `id` keys for the
questionnaire, questions, or options, as these will be generated by the
back end).

The JSON response will include `id` keys:

    {
        "status": "ok",
        "result": {
            "id": 2,
            /* ... the rest of the questionnaire object ... */
        }
    }

#### Reusing questions between questionnaires

**NOT IMPLEMENTED**

You can reuse questions by citing them by `id` rather than listing their
characteristics. So POST, e.g., to create a new questionnaire based on
the sample "Questionnaire One" above:

    {
        "title": "Copy of Questionnaire One",
        "questions": [
            { "id": 1 },
            { "id": 2 },
            { "id": 3 }
        ]
    }

### GET /api/questionnaire

Gets a list of existing published questionnaires.

JSON response:

    {
        "status": "ok",
        "result": {
            "count": 2,
            "list": [
                {
                    "id": 1,
                    "title": "Questionnaire One"
                },
                {
                    "id": 2,
                    "title": "Questionnaire Two"
                }
            ]
        }
    }

### GET /api/questionnaire/{questionnaire_id}

Gets the metadata and questions for a questionnaire.

JSON response:

    {
        "status": "ok",
        "result": {
            "id": 1,
            "title": "Questionnaire One",
            "is_published": true,
            "questions": [
                /* ... the rest of the questionnaire object ... */
            ]
        }
    }

### PUT /api/questionnaire/{questionnaire_id}

Modify a questionnaire.

**NOT IMPLEMENTED**

This can be used to:

* edit the title or questions associated with an unpublished
  questionnaire,
* publish a questionnaire.

Once a questionnaire is published it can accept responses, but none of
its questions or metadata can be further modified.

Once published, a questionnaire cannot be unpublished. (In the future,
we may want to to be able to unpublish a questionnaire. For example, if
you want to revise an existing questionnaire, you'd publish a revised
version and unpublish the old version. But this would have to be done in
such a way that no _previously_ published questionnaires could be
modified. Previous responses to old questionnaires would be preserved.)

### POST /api/questionnaire/{questionnaire_id}/response

Saves a user's response to a questionnaire.

**PARTIALLY IMPLEMENTED**, but as a POST to
`/api/questionnaire/{questionnaire_id}`.

Only published questionnaires accept responses. The same questionnaire
can be filled out multiple times by the same user and accept multiple
responses. Each will be given a `response_id`.

POST the following JSON:

    {
        "user_id": 123,
        "answers": {
            "1": "Toby",
            "2": 4,
            "3": [6, 8]
        },
    }

The above represents the following answers to the questionnaire shown
earlier:

* What is your name? _Toby_.
* What is your favourite colour? _Green_ (option id 4).
* Do you have a pet? _Cat_, _Other_ (option ids 6 and 8).

Text answers are posted as plain text. Single-option answers are posted
as the numeric ID of the selected option. Multi-option answers are
posted as an array of numeric IDs (always an array, even if only one
option is selected, and the array may be empty if no options were
selected).

### GET /api/questionnaire/{questionnaire_id}/response

Get a list of responses to a questionnaire.

**NOT IMPLEMENTED**

JSON response:

    {
        "status": "ok",
        "result": {
            "count": 2,
            "list": [
                {
                    "id": 1,
                    "questionnaire_id": 1,
                    "answered_at": "2021-10-09 23:03:34"
                },
                {
                    "id": 2,
                    "questionnaire_id": 1,
                    "answered_at": "2021-10-11 02:19:08"
                }
            ]
        }
    }

### GET /api/questionnaire/{questionnaire_id}/response/{response_id}

Get a response to a questionnaire.

**NOT IMPLEMENTED**

### GET /api/user/{user_id}/response

Get a list of an individual user's responses to questionnaires.

**NOT IMPLEMENTED**

The JSON response is in the same format
as `/api/questionnaire/{questionnaire_id}/response`.

