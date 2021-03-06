# coding: utf-8
require 'rails_helper'

describe 'markdown' do
  let(:upload_url) { '' }
  before do
    allow(MarkdownTopicConverter.instance).to receive(:upload_url).and_return(upload_url)
  end

  describe MarkdownTopicConverter do
    let(:raw) { '' }
    let!(:doc) { Nokogiri::HTML.fragment(MarkdownTopicConverter.format(raw)) }
    subject { doc }

    describe 'heading' do
      subject { super().inner_html }

      context 'h1' do
        let(:raw) { "# foo Bar 的" }
        it { is_expected.to eq(%(<h2 id="foo Bar 的">foo Bar 的</h2>))}
      end

      context 'h2' do
        let(:raw) { "## 这是什么" }
        it { is_expected.to eq(%(<h2 id="这是什么">这是什么</h2>))}
      end

      context 'h3' do
        let(:raw) { "### 这是什么" }
        it { is_expected.to eq(%(<h3 id="这是什么">这是什么</h3>))}
      end

      context 'h4' do
        let(:raw) { "#### 这是什么" }
        it { is_expected.to eq(%(<h4 id="这是什么">这是什么</h4>))}
      end

      context 'h5' do
        let(:raw) { "##### 这是什么" }
        it { is_expected.to eq(%(<h5 id="这是什么">这是什么</h5>))}
      end

      context 'h6' do
        let(:raw) { "###### 这是什么" }
        it { is_expected.to eq(%(<h6 id="这是什么">这是什么</h6>))}
      end
    end

    describe "encoding with Chinese chars" do
      context "a simple" do
        let(:raw) { '#1楼 @ichord 刚刚发布，有点问题' }

        describe '#inner_html' do
          subject { super().inner_html }
          it { is_expected.to eq(%(<p><a href="#reply1" class="at_floor" data-floor="1">#1楼</a> <a href="/ichord" class="at_user" title="@ichord"><i>@</i>ichord</a> 刚刚发布，有点问题</p>)) }
        end
      end
    end

    describe 'strikethrough' do
      let(:raw) { "some ~~strikethrough~~ text" }

      describe '#inner_html' do
        subject { super().inner_html }
        it { is_expected.to eq(%(<p>some <del>strikethrough</del> text</p>)) }
      end
    end

    describe 'strong' do
      let(:raw) { "some **strong** text" }

      describe '#inner_html' do
        subject { super().inner_html }
        it { is_expected.to eq(%(<p>some <strong>strong</strong> text</p>)) }
      end
    end

    describe 'at user' do
      context '@user in text' do
        let(:raw) { '@foo' }

        it 'has a link' do
          expect(doc.css('a').size).to eq(1)
          expect(doc.inner_html).to eq(%(<p><a href="/foo" class="at_user" title="@foo"><i>@</i>foo</a></p>))
        end

        describe 'the link' do
          subject { doc.css('a').first }

          describe '[:href]' do
            subject { super()[:href] }
            it { is_expected.to eq('/foo') }
          end

          describe '[:class]' do
            subject { super()[:class] }
            it { is_expected.to eq('at_user') }
          end

          describe '[:title]' do
            subject { super()[:title] }
            it { is_expected.to eq('@foo') }
          end

          describe '#inner_html' do
            subject { super().inner_html }
            it { is_expected.to eq('<i>@</i>foo') }
          end
        end
      end

      context '@_underscore_ in text' do
        let(:raw) { '@_underscore_' }

        it 'has a link' do
          expect(doc.css('a').size).to eq(1)
        end

        describe 'the link' do
          subject { doc.css('a').first }

          describe '[:href]' do
            subject { super()[:href] }
            it { is_expected.to eq('/_underscore_') }
          end

          describe '[:class]' do
            subject { super()[:class] }
            it { is_expected.to eq('at_user') }
          end

          describe '[:title]' do
            subject { super()[:title] }
            it { is_expected.to eq('@_underscore_') }
          end

          describe '#inner_html' do
            subject { super().inner_html }
            it { is_expected.to eq('<i>@</i>_underscore_') }
          end
        end
      end

      context '@__underscore__ in text' do
        let(:raw) { '@__underscore__' }

        it 'has a link' do
          expect(doc.css('a').size).to eq(1)
        end

        describe 'the link' do
          subject { doc.css('a').first }

          describe '[:href]' do
            subject { super()[:href] }
            it { is_expected.to eq('/__underscore__') }
          end

          describe '[:class]' do
            subject { super()[:class] }
            it { is_expected.to eq('at_user') }
          end

          describe '[:title]' do
            subject { super()[:title] }
            it { is_expected.to eq('@__underscore__') }
          end

          describe '#inner_html' do
            subject { super().inner_html }
            it { is_expected.to eq('<i>@</i>__underscore__') }
          end
        end
      end

      context '@small_fish__ in text' do
        let(:raw) { '@small_fish__' }
        specify { expect(doc.css('a').first.inner_html).to eq('<i>@</i>small_fish__') }
      end

      context '@small_fish__ in code block' do
        let(:raw) { '`@small_fish__`' }
        specify { expect(doc.css('code').first.inner_html).to eq('@small_fish__') }
      end

      context '@small_fish__ in ruby code block' do
        let(:raw) {
          <<-MD.gsub(/^ {12}/, '')
            ```ruby
            @small_fish__ = 100
            ```
          MD
        }

        specify { expect(doc.search('pre code').children[0].inner_html).to eq('@small_fish__') }
      end

      context '@user in code' do
        let(:raw) { '`@user`' }

        specify { expect(doc.css('a')).to be_empty }
        specify { expect(doc.css('code').inner_html).to eq('@user') }
      end

      context '@user in block code' do
        let(:raw) {
          <<-MD.gsub(/^ {12}/, '')
            ```
            @user
            ```
          MD
        }

        specify { expect(doc.css('a')).to be_empty }
        specify { expect(doc.css('pre code').inner_html).to eq("@user") }
      end

      context '@var in coffeescript' do
        let(:raw) {
          <<-MD.gsub(/^ {12}/, '')
            ```coffeescript
            @var
            ```
          MD
        }

        it 'should not leave it as placeholder' do
          expect(doc.to_html).to include('var')
        end
      end
    end

    # }}}

    # {{{ describe mention floor

    describe 'mention floor' do
      context ' #12f in text' do
        let(:raw) { '#12f' }

        it 'has a link' do
          expect(doc.css('a').size).to eq(1)
        end

        describe 'the link' do
          subject { doc.css('a').first }

          describe '[:href]' do
            subject { super()[:href] }
            it { is_expected.to eq('#reply12') }
          end

          describe '[:class]' do
            subject { super()[:class] }
            it { is_expected.to eq('at_floor') }
          end

          describe "['data-floor']" do
            subject { super()['data-floor'] }
            it { is_expected.to eq('12') }
          end

          describe '#inner_html' do
            subject { super().inner_html }
            it { is_expected.to eq('#12f') }
          end
        end
      end

      context ' #12f in code' do
        let(:raw) { '`#12f`' }

        specify { expect(doc.css('a')).to be_empty }
        specify { expect(doc.css('code').inner_html).to eq('#12f') }
      end

      context ' #12f in block code' do
        let(:raw) {
          <<-MD.gsub(/^ {12}/, '')
            ```
            #12f
            ```
          MD
        }

        specify { expect(doc.css('a')).to be_empty }
        specify { expect(doc.css('pre code').inner_html).to eq("#12f") }
      end
    end

    # }}}

    # {{{ describe 'emoji'

    describe 'emoji' do
      context ':apple: in text' do
        let(:raw) { ':apple:' }

        it 'has a image' do
          expect(doc.css('img').size).to eq(1)
        end

        describe 'the image' do
          subject { doc.css('img').first }

          describe '[:src]' do
            subject { super()[:src] }
            it { is_expected.to eq("#{upload_url}/assets/emojis/apple.png") }
          end

          describe '[:class]' do
            subject { super()[:class] }
            it { is_expected.to eq('emoji') }
          end

          describe '[:title]' do
            subject { super()[:title] }
            it { is_expected.to eq(':apple:') }
          end
        end
      end

      context ':-1:' do
        let(:raw) { ':-1:' }
        specify { expect(doc.css('img').first[:title]).to eq(':-1:') }
      end
      context ':arrow_lower_left:' do
        let(:raw) { ':arrow_lower_left:' }
        specify { expect(doc.css('img').first[:title]).to eq(':arrow_lower_left:') }
      end

      context ':apple: in code' do
        let(:raw) { '`:apple:`' }

        specify { expect(doc.css('a')).to be_empty }
        specify { expect(doc.css('code').inner_html).to eq(':apple:') }
      end

      context ':apple: in block code' do
        let(:raw) {
          <<-MD.gsub(/^ {12}/, '')
            ```
            :apple:
            ```
          MD
        }

        specify { expect(doc.css('a')).to be_empty }
        specify { expect(doc.css('pre code').inner_html).to eq(":apple:") }
      end
    end

    # }}}

    describe 'The code' do
      context '``` use with code' do
        let(:raw) {
          %(```
          class Foo; end
          ```)
        }

        specify { expect(doc.css('pre').attr("class").value).to eq("highlight plaintext") }
      end

      context '```ruby use with code' do
        let(:raw) {
          %(```ruby
          class Foo; end
          ```)
        }

        specify { expect(doc.css('pre').attr("class").value).to eq("highlight ruby") }
      end

      context 'indent in raw with \t' do
        let(:raw) { "\t\tclass Foo; end" }

        specify { expect(doc.css('pre')).to be_empty }
      end

      context 'indent in raw with space' do
        let(:raw) { "    class Foo; end" }

        specify { expect(doc.css('pre')).to be_empty }
      end
    end

    describe 'tables' do
      let(:raw) { %(
| header 1 | header 3 |
| -------- | -------- |
| cell 1   | cell 2   |
| cell 3   | cell 4   |) }

      it { expect(doc.inner_html).to eq "<table class=\"table table-bordered table-striped\">\n<tr>\n<th>header 1</th>\n<th>header 3</th>\n</tr>\n<tr>\n<td>cell 1</td>\n<td>cell 2</td>\n</tr>\n<tr>\n<td>cell 3</td>\n<td>cell 4</td>\n</tr>\n</table>" }
    end

    describe 'Escape HTML tags' do
      context '<xxx> or a book names' do
        let(:raw) { "<Enterprise Integration Patterns> book" }

        describe '#inner_html' do
          subject { super().inner_html }
          it { is_expected.to eq("<p>&lt;Enterprise Integration Patterns&gt; book</p>") }
        end
      end

      context '<img> tag' do
        let(:raw) { "<img src='aaa.jpg' /> aaa" }

        describe '#inner_html' do
          subject { super().inner_html }
          it { is_expected.to eq("<p>&lt;img src='aaa.jpg' /&gt; aaa</p>") }
        end
      end

      context '<b> tag' do
        let(:raw) { "<b>aaa</b>" }

        describe '#inner_html' do
          subject { super().inner_html }
          it { is_expected.to eq("<p>&lt;b&gt;aaa&lt;/b&gt;</p>") }
        end
      end

      context "<a> tag" do
        let(:raw) { "https://www.flickr.com/photos/123590011@N08/sets/72157644587013882/" }

        subject { super().inner_html }
        it "auto link with @ issue #322" do
          expect(subject).to eq "<p><a href=\"https://www.flickr.com/photos/123590011@N08/sets/72157644587013882/\" rel=\"nofollow\" target=\"_blank\">https://www.flickr.com/photos/123590011@N08/sets/72157644587013882/</a></p>"
        end
      end
    end
    
    describe 'Full example' do
      let(:raw) {
        %(# Markdown

Markdown is a text formatting syntax inspired on plain text email. In the words of its creator, [John Gruber][]:

> The idea is that a Markdown-formatted document should be publishable as-is, as plain text, without looking like it’s been marked up with tags or formatting instructions.

[John Gruber]: http://daringfireball.net/


## Syntax Guide - Heading 2

### Strong and Emphasize - Heading 3

#### Heading 4

##### Heading 5

###### Heading 6

```
*emphasize*    **strong**
_emphasize_    __strong__
```

----

**Shortcuts**

- Add/remove bold:

  ⌘-B for Mac / Ctrl-B for Windows and Linux

- Add/remove italic:

  ⌘-I for Mac / Ctrl-I for windows and Linux

### List

- Ruby
  - Rails
    - ActiveRecord
- Go
  - Gofmt
  - Revel
- Node.js
  - Koa
  - Express

### Number List

1. Node.js
2. Ruby
3. Go

### Tables

| header 1 | header 3 |
| -------- | -------- |
| cell 1   | cell 2   |
| cell 3   | cell 4   |

### Links

Inline links:

[link text](http://url.com/ "title")
[link text](http://url.com/)


```rb
class Foo
end
```)
      }
      let(:out) {
        %(<h2 id="Markdown">Markdown</h2>
<p>Markdown is a text formatting syntax inspired on plain text email. In the words of its creator, <a href="http://daringfireball.net/" target="_blank">John Gruber</a>:</p>

<blockquote>
<p>The idea is that a Markdown-formatted document should be publishable as-is, as plain text, without looking like it’s been marked up with tags or formatting instructions.</p>
</blockquote>
<h2 id="Syntax Guide - Heading 2">Syntax Guide - Heading 2</h2><h3 id="Strong and Emphasize - Heading 3">Strong and Emphasize - Heading 3</h3><h4 id="Heading 4">Heading 4</h4><h5 id="Heading 5">Heading 5</h5><h6 id="Heading 6">Heading 6</h6><pre class="highlight plaintext"><code>*emphasize*    **strong**
_emphasize_    __strong__</code></pre>

<hr>

<p><strong>Shortcuts</strong></p>

<ul>
<li>Add/remove bold:</li>
</ul>

<p>⌘-B for Mac / Ctrl-B for Windows and Linux</p>

<ul>
<li>Add/remove italic:</li>
</ul>

<p>⌘-I for Mac / Ctrl-I for windows and Linux</p>
<h3 id="List">List</h3>
<ul>
<li>Ruby

<ul>
<li>Rails</li>
<li>ActiveRecord</li>
</ul>
</li>
<li>Go

<ul>
<li>Gofmt</li>
<li>Revel</li>
</ul>
</li>
<li>Node.js

<ul>
<li>Koa</li>
<li>Express</li>
</ul>
</li>
</ul>
<h3 id="Number List">Number List</h3>
<ol>
<li>Node.js</li>
<li>Ruby</li>
<li>Go</li>
</ol>
<h3 id="Tables">Tables</h3><table class="table table-bordered table-striped">
<tr>
<th>header 1</th>
<th>header 3</th>
</tr>
<tr>
<td>cell 1</td>
<td>cell 2</td>
</tr>
<tr>
<td>cell 3</td>
<td>cell 4</td>
</tr>
</table><h3 id="Links">Links</h3>
<p>Inline links:</p>

<p><a href="http://url.com/" title="title" target="_blank">link text</a><br>
<a href="http://url.com/" target="_blank">link text</a></p>
<pre class="highlight ruby"><code><span class="k">class</span> <span class="nc">Foo</span>
<span class="k">end</span></code></pre>)
      }
    
      it 'should work' do
        expect(doc.inner_html).to eq(out)
      end
    end
  end
  
  
end
