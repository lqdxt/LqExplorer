# Lq Explorer — Source-Available License v1.0

**Copyright (c) 2026 Liquidoxity. All rights reserved.**

---

## Plain-English Summary

*(This box is a courtesy summary. The numbered terms below are the actual license.)*

- You **may** read, study, and run the code.
- You **may** copy, fork, and modify the source code.
- You **may** distribute copies and forks, provided they stay named **"Lq Explorer"** and include this license.
- You **may** write and distribute your own **plugins** that interact with Lq Explorer — they remain fully yours.
- You **may not** rebrand, rename, or present the software (or any fork) under any other name.
- You **may not** strip runtime credit markers or watermarks, though source-level header comments may be modified or removed.
- You **may not** sell the software or use it in a commercial product without written permission.
- Any breach **ends this license immediately**.
- Provided **as is**, with no warranty and no liability.

---

## 1. Grant of Rights

You are permitted to:

(a) view, read, and study the source code of Lq Explorer;

(b) run the **unmodified official distribution** for personal,
    non-commercial use inside Roblox;

(c) copy, fork, and modify the source code;

(d) distribute copies and forks of the software, provided you
    comply with Section 2;

(e) reference short excerpts for commentary, review, or education,
    provided clear attribution to Liquidoxity and the name
    "Lq Explorer" are included;

(f) write, publish, and distribute your own **plugins** (see Section 5).

No other rights are granted, whether by implication, estoppel,
or otherwise.

---

## 2. Conditions

Any copy, fork, or distribution under 1(c) or 1(d) must:

(a) include this license in full (for example, as a LICENSE.md file
    in the repository root or equivalent);

(b) keep the software named **"Lq Explorer"**, including in the
    repository name, README, window title, menu labels, and any
    other user-facing surface;

(c) retain any copyright notice, credit marker, or attribution
    watermark that the software emits at runtime (such as in the
    window title, about text, or console output). Source-level
    header comments may be modified or removed;

(d) clearly state, in the README or equivalent, that the copy or
    fork is a modified version of Lq Explorer and describe the
    changes made, if any.

---

## 3. Prohibited Uses

You are **not** permitted to:

(a) rebrand, rename, or present the software (or any copy, fork,
    or derivative) under any name, logo, or identity other than
    "Lq Explorer";

(b) remove, alter, or obscure any copyright notice, credit marker,
    or attribution watermark that the software emits at runtime;

(c) redistribute, sublicense, sell, rent, or otherwise make the
    software available for payment or as part of a paid product
    or service without prior written permission from the copyright
    holder;

(d) misrepresent the software, or any fork of it, as your own
    original work or as the work of anyone other than Liquidoxity
    and its contributors.

---

## 4. Attribution

This license does not require source-level header comments or a
per-file copyright notice. Attribution is satisfied by complying
with Sections 2(b) and 2(c): the software must remain named
"Lq Explorer" in user-facing surfaces, and runtime credit markers
must not be removed.

Fork authors are encouraged, but not required, to include the
following notice in their README:

> "Lq Explorer — Copyright (c) 2026 Liquidoxity. Used under the
> Lq Explorer Source-Available License v1.0."

---

## 5. Plugins, Extensions, and Add-ons

Plugins that **interact with** Lq Explorer at runtime are **independent
works**. Their authors retain full copyright and may license them under
any terms they choose. This license does not extend to, restrict, or
claim any ownership over such plugins.

"Interact with" includes, without limitation:

- calling public API functions (`Explorer.RegisterContextItem`,
  `Explorer.RegisterIcon`, `Explorer.AddSetting`, `Explorer.AddMenuButton`,
  `Explorer.AddDropdown`, `Explorer.SetSource`, `Explorer.SetHighlighter`,
  `Explorer.DefineProperty`, `Explorer.OnSelect` / `OnDoubleClick` /
  `OnRightClick`, etc.);
- reading or writing state on the `Explorer` table or its sub-tables;
- hooking, wrapping, monkeypatching, or replacing functions on the
  `Explorer` table or its sub-tables;
- hooking internal closures reached via `getgenv()`, `getgc()`,
  `debug.getupvalues`, or similar introspection;
- overriding callbacks, intercepting events, or observing state changes.

Referencing Lq Explorer through any of these mechanisms does **not**
make a plugin a derivative work, and does not subject it to this
license.

**Loophole closure:** *reproducing* any portion of the Lq Explorer
source code inside a plugin — i.e., embedding, copying, vendoring, or
redistributing actual Lq Explorer source rather than referencing it —
is permitted under Section 1(c) but remains subject to Section 2 and
Section 3. Code that originates in Lq Explorer remains covered by this
license wherever it is shipped, regardless of the label it is shipped
under.

**Attribution:** if a plugin programmatically removes, suppresses, or
forges the copyright notice, credit marker, or attribution watermark
emitted by Lq Explorer itself, that removal is a violation of
Section 3(b) regardless of whether the surrounding plugin is otherwise
independent.

---

## 6. Trademarks

The name **"Lq Explorer"**, including all case variants (such as
"LQ Explorer" and "lq explorer"), and any associated logos or
branding are the exclusive marks of the copyright holder. This
license grants no right to use them except as required for the
naming requirement under Section 2(b).

Forks must retain the name "Lq Explorer" per Section 2(b), but this
does not grant the fork author any ownership of the mark.

---

## 7. Termination

This license terminates **automatically, without notice**, upon any
breach of Sections 2, 3, or 7.

Upon termination you must immediately cease all use, delete all copies
in your possession or control, and remove the software from any public
or private distribution channel.

3, 6, 7, 9, and 10 survive termination.

---

## 8. Disclaimer of Warranty

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND
NON-INFRINGEMENT. THE COPYRIGHT HOLDER SHALL NOT BE LIABLE FOR ANY
CLAIM, DAMAGES, OR OTHER LIABILITY ARISING FROM, OUT OF, OR IN
CONNECTION WITH THE SOFTWARE OR ITS USE.

---

## 9. Limitation of Liability

IN NO EVENT SHALL THE COPYRIGHT HOLDER BE LIABLE FOR ANY SPECIAL,
INCIDENTAL, INDIRECT, OR CONSEQUENTIAL DAMAGES (INCLUDING, WITHOUT
LIMITATION, LOSS OF DATA, LOSS OF PROFITS, OR BUSINESS INTERRUPTION)
ARISING FROM THE USE OR INABILITY TO USE THE SOFTWARE, EVEN IF ADVISED
OF THE POSSIBILITY OF SUCH DAMAGES.

---

## 10. Governing Law

This license is governed by the laws of the copyright holder's
jurisdiction, without regard to conflict-of-law principles. Any
dispute shall be resolved in the courts of that jurisdiction.

---

*End of License — Lq Explorer Source-Available License v1.0*
