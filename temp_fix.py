import re


def process_file(filepath):
    with open(filepath, "r", encoding="utf-8") as f:
        code = f.read()

    code = code.replace("noItemsFoundBuilder: (context)", "emptyBuilder: (context)")
    code = code.replace("onSuggestionSelected:", "onSelected:")

    def replacer(m):
        inner = m.group(1)
        ctrl_match = re.search(r"controller:\s*([a-zA-Z0-9_\[\]\.]+),", inner)
        ctrl_name = ctrl_match.group(1) if ctrl_match else "null"
        inner = re.sub(
            r"controller:\s*[a-zA-Z0-9_\[\]\.]+,\s*",
            "controller: controller,\nfocusNode: focusNode,\n",
            inner,
        )
        return f"controller: {ctrl_name},\nbuilder: (context, controller, focusNode) => TextField({inner}"

    code = re.sub(
        r"textFieldConfiguration:\s*TextFieldConfiguration\((.*?contentPadding:\s*EdgeInsets\.symmetric\(horizontal:\s*8\.0\)\),\s*)",
        replacer,
        code,
        flags=re.DOTALL,
    )

    with open(filepath, "w", encoding="utf-8") as f:
        f.write(code)
    print(f"{filepath} fixed!")


process_file("lib/screens/filter.dart")
