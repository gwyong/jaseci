
node faq_root;
node faq_state {
    has question;
    has answer;
    // "has" keyword defines nodes variables.
}

// Static graph definition
graph faq {
    has anchor faq_root;
    // An anchor node is required for every graph block
    // It must be assigned inside the spawn block of the graph definition.
    spawn {
        // Spawning the nodes
        faq_root = spawn node::faq_root;
        
        faq_answer_1 = spawn node::faq_state(
            question = "How do I configure my order?",
            answer = "To configure your order, log into your Tesla account and select manage on your existing reservation to configure your Tesla. Your original USD deposit has now been converted to SGD."
        );
        
        faq_answer_2 = spawn node::faq_state(
            question = "How do I order a Tesla?",
            answer = "Visit our design studio to place your order. The purchase price and estimated delivery date will change based on your configuration."
        );

        faq_answer_3 = spawn node::faq_state(
            question = "Can I request a test drive?",
            answer = "Yes, you can request for a test drive. Please note that drivers must be a minimum of 25 years of age and not exceeding 65 years of age, hold a full driving license with over 2 years of driving experience. Insurance conditions relating to your specific status must be reviewed and accepted prior to the test drive."
        );

        // Connecting the nodes together
        faq_root --> faq_answer_1;
        faq_root --> faq_answer_2;
        faq_root --> faq_answer_3;
    }
}

walker init {
    root {
        // spawn here --> graph::faq;
        spawn here --> node::faq_root;
        spawn here walker::ingest_faq(kb_file="tesla_faq.json");
        spawn here walker::ask;
    }
}
// walker, called 'init', contains logic specifically for the root node.
// It means that the code inside the root {} block will run only on the root node.
// Every Jac program starts with a single root node.
// A walker can be executed on any nodes, though the root is used by default if none is specified.
// 'init' can be viewed as similar to 'main' in python.
// 'here' always evaluates to the specific node the walker is currently on.

walker ask {
    can use.qa_classify;
    has question;
    root {
        question = std.input(">");
        take --> node::faq_root;
    }
    faq_root {
        answers = -->.answer;
        best_answer = use.qa_classify(
            text = question,
            classes = answers
        );
        take --> node::faq_state(answer==best_answer["match"]);
    }
    faq_state {
        std.out(here.answer);
    }
}
// std.input and std.output read and write to the cmd line.
// '-->.answer' collects the 'answer' variable of all of the nodes that are connected to here/faq_root with a --> connection.
// use.qa_classify is one of the action supported by the USE QA action set.

walker ingest_faq{
    has kb_file;
    root: take --> node::faq_root;
    faq_root {
        kb = file.load_json(kb_file);
        for faq in kb {
            answer = faq["answer"];
            spawn here --> node::faq_state(answer=answer);
        }
    }
}