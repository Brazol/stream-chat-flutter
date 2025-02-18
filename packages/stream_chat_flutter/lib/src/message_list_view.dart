// ignore_for_file: lines_longer_than_80_chars
import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:stream_chat_flutter/scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:stream_chat_flutter/src/extension.dart';
import 'package:stream_chat_flutter/src/swipeable.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

/// Widget builder for message
/// [defaultMessageWidget] is the default [StreamMessageWidget] configuration
/// Use [defaultMessageWidget.copyWith] to easily customize it
typedef MessageBuilder = Widget Function(
  BuildContext,
  MessageDetails,
  List<Message>,
  StreamMessageWidget defaultMessageWidget,
);

/// Widget builder for parent message
/// [defaultMessageWidget] is the default [StreamMessageWidget] configuration
/// Use [defaultMessageWidget.copyWith] to easily customize it
typedef ParentMessageBuilder = Widget Function(
  BuildContext,
  Message?,
  StreamMessageWidget defaultMessageWidget,
);

/// Widget builder for system message
typedef SystemMessageBuilder = Widget Function(
  BuildContext,
  Message,
);

/// Widget builder for thread
typedef ThreadBuilder = Widget Function(BuildContext context, Message? parent);

/// Callback for thread taps
typedef ThreadTapCallback = void Function(Message, Widget?);

/// Callback on message swiped
typedef OnMessageSwiped = void Function(Message);

/// Callback on message tapped
typedef OnMessageTap = void Function(Message);

/// Callback on reply tapped
typedef ReplyTapCallback = void Function(Message);

/// Spacing Types (These are properties of a message to help inform the decision
/// of how much space / which widget to build after it)
enum SpacingType {
  /// Message is a thread
  thread,

  /// There is a >1s time diff between current and last message
  timeDiff,

  /// Next message is by a different user
  otherUser,

  /// Message is deleted
  deleted,

  /// No other conditions are valid, default spacing (This will likely be the
  /// only rule in the list provided)
  defaultSpacing,
}

/// Builder for building certain spacing after widgets.
/// This spacing can be in form of any widgets you like.
/// A List of [SpacingType] is provided to help inform the decision of
/// what to build after the message.
///
/// As an example:
///               MessageListView(
///                 spacingWidgetBuilder: (context, list) {
///                   if(list.contains(SpacingType.defaultSpacing)) {
///                     return SizedBox(height: 2.0,);
///                   } else {
///                     return SizedBox(height: 8.0,);
///                   }
///                 },
///               ),
typedef SpacingWidgetBuilder = Widget Function(
  BuildContext context,
  List<SpacingType> spacingTypes,
);

/// Class for message details
// ignore: prefer-match-file-name
class MessageDetails {
  /// Constructor for creating [MessageDetails]
  MessageDetails(
    String currentUserId,
    this.message,
    List<Message> messages,
    this.index,
  ) {
    isMyMessage = message.user?.id == currentUserId;
    isLastUser = index + 1 < messages.length &&
        message.user?.id == messages[index + 1].user?.id;
    isNextUser =
        index - 1 >= 0 && message.user!.id == messages[index - 1].user?.id;
  }

  /// True if the message belongs to the current user
  late final bool isMyMessage;

  /// True if the user message is the same of the previous message
  late final bool isLastUser;

  /// True if the user message is the same of the next message
  late final bool isNextUser;

  /// The message
  final Message message;

  /// The index of the message
  final int index;
}

/// {@macro message_list_view}
@Deprecated("Use 'StreamMessageListView' instead")
typedef MessageListView = StreamMessageListView;

/// {@template message_list_view}
/// ![screenshot](https://raw.githubusercontent.com/GetStream/stream-chat-flutter/master/packages/stream_chat_flutter/screenshots/message_listview.png)
/// ![screenshot](https://raw.githubusercontent.com/GetStream/stream-chat-flutter/master/packages/stream_chat_flutter/screenshots/message_listview_paint.png)
///
/// It shows the list of messages of the current channel.
///
/// ```dart
/// class ChannelPage extends StatelessWidget {
///   const ChannelPage({
///     Key? key,
///   }) : super(key: key);
///
///   @override
///   Widget build(BuildContext context) => Scaffold(
///         appBar: const StreamChannelHeader(),
///         body: Column(
///           children: <Widget>[
///             Expanded(
///               child: StreamMessageListView(
///                 threadBuilder: (_, parentMessage) => ThreadPage(
///                   parent: parentMessage,
///                 ),
///               ),
///             ),
///             const StreamMessageInput(),
///           ],
///         ),
///       );
/// }
/// ```
///
///
/// Make sure to have a [StreamChannel] ancestor in order to
/// provide the information about the channels.
/// The widget uses a [ListView.custom] to render the list of channels.
///
/// The widget components render the ui based on the first
/// ancestor of type [StreamChatTheme].
/// Modify it to change the widget appearance.
/// {@endtemplate}
class StreamMessageListView extends StatefulWidget {
  /// Instantiate a new StreamMessageListView.
  const StreamMessageListView({
    super.key,
    this.showScrollToBottom = true,
    this.scrollToBottomBuilder,
    this.messageBuilder,
    this.parentMessageBuilder,
    this.parentMessage,
    this.threadBuilder,
    this.onThreadTap,
    this.dateDividerBuilder,
    this.scrollPhysics =
        const ClampingScrollPhysics(), // we need to use ClampingScrollPhysics to avoid the list view to animate and break while loading
    this.initialScrollIndex,
    this.initialAlignment,
    this.scrollController,
    this.itemPositionListener,
    this.onMessageSwiped,
    this.highlightInitialMessage = false,
    this.messageHighlightColor,
    this.showConnectionStateTile = false,
    this.headerBuilder,
    this.footerBuilder,
    this.loadingBuilder,
    this.emptyBuilder,
    this.systemMessageBuilder,
    this.messageListBuilder,
    this.errorBuilder,
    this.messageFilter,
    this.onMessageTap,
    this.onSystemMessageTap,
    this.showFloatingDateDivider = true,
    this.threadSeparatorBuilder,
    this.unreadMessagesSeparatorBuilder,
    this.messageListController,
    this.reverse = true,
    this.paginationLimit = 20,
    this.paginationLoadingIndicatorBuilder,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.onDrag,
    this.spacingWidgetBuilder = _defaultSpacingWidgetBuilder,
  });

  /// [ScrollViewKeyboardDismissBehavior] the defines how this [PositionedList] will
  /// dismiss the keyboard automatically.
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;

  /// Function used to build a custom message widget
  final MessageBuilder? messageBuilder;

  /// Whether the view scrolls in the reading direction.
  ///
  /// Defaults to true.
  ///
  /// See [ScrollView.reverse].
  final bool reverse;

  /// Limit used during pagination
  final int paginationLimit;

  /// Function used to build a custom system message widget
  final SystemMessageBuilder? systemMessageBuilder;

  /// Function used to build a custom parent message widget
  final ParentMessageBuilder? parentMessageBuilder;

  /// Function used to build a custom thread widget
  final ThreadBuilder? threadBuilder;

  /// Function called when tapping on a thread
  /// By default it calls [Navigator.push] using the widget
  /// built using [threadBuilder]
  final ThreadTapCallback? onThreadTap;

  /// If true will show a scroll to bottom message when there are new
  /// messages and the scroll offset is not zero
  final bool showScrollToBottom;

  /// Function used to build a custom scroll to bottom widget
  ///
  /// Provides the current unread messages count and a reference
  /// to the function that is executed on tap of this widget by default
  ///
  /// As an example:
  ///           MessageListView(
  ///             scrollToBottomBuilder: (unreadCount, defaultTapAction) {
  ///               return InkWell(
  ///                 onTap: () => defaultTapAction(unreadCount),
  ///                 child: Text('Scroll To Bottom'),
  ///               );
  ///             },
  ///           ),
  final Widget Function(
    int unreadCount,
    Future<void> Function(int) scrollToBottomDefaultTapAction,
  )? scrollToBottomBuilder;

  /// Parent message in case of a thread
  final Message? parentMessage;

  /// Builder used to render date dividers
  final Widget Function(DateTime)? dateDividerBuilder;

  /// Index of an item to initially align within the viewport.
  final int? initialScrollIndex;

  /// Determines where the leading edge of the item at [initialScrollIndex]
  /// should be placed.
  final double? initialAlignment;

  /// Controller for jumping or scrolling to an item.
  final ItemScrollController? scrollController;

  /// Provides a listenable iterable of [itemPositions] of items that are on
  /// screen and their locations.
  final ItemPositionsListener? itemPositionListener;

  /// The ScrollPhysics used by the ListView
  final ScrollPhysics? scrollPhysics;

  /// Called when message item gets swiped
  final OnMessageSwiped? onMessageSwiped;

  /// If true the list will highlight the initialMessage if there is any.
  ///
  /// Also See [StreamChannel]
  final bool highlightInitialMessage;

  /// Color used while highlighting initial message
  final Color? messageHighlightColor;

  /// Flag for showing tile on header
  final bool showConnectionStateTile;

  /// Flag for showing the floating date divider
  final bool showFloatingDateDivider;

  /// Function called when messages are fetched
  final Widget Function(BuildContext, List<Message>)? messageListBuilder;

  /// Function used to build a header widget
  final WidgetBuilder? headerBuilder;

  /// Function used to build a footer widget
  final WidgetBuilder? footerBuilder;

  /// Function used to build a loading widget
  final WidgetBuilder? loadingBuilder;

  /// Function used to build an empty widget
  final WidgetBuilder? emptyBuilder;

  /// Callback triggered when an error occurs while performing the
  /// given request.
  /// This parameter can be used to display an error message to
  /// users in the event
  /// of a connection failure.
  final ErrorBuilder? errorBuilder;

  /// Predicate used to filter messages
  final bool Function(Message)? messageFilter;

  /// Called when any message is tapped except a system message
  /// (use [onSystemMessageTap] instead)
  final OnMessageTap? onMessageTap;

  /// Called when system message is tapped
  final OnMessageTap? onSystemMessageTap;

  /// Builder used to build the thread separator in case it's a thread view
  final WidgetBuilder? threadSeparatorBuilder;

  /// Builder used to build the unread message separator
  final Widget Function(BuildContext context, int unreadCount)?
      unreadMessagesSeparatorBuilder;

  /// A [MessageListController] allows pagination.
  /// Use [ChannelListController.paginateData] pagination.
  final MessageListController? messageListController;

  /// Builder used to build the loading indicator shown while paginating.
  final WidgetBuilder? paginationLoadingIndicatorBuilder;

  /// This allows a user to customise the space after a message
  /// A List of [SpacingType] is provided to provide more data about the
  /// type of message (thread, difference in time between current and last
  /// message, default spacing, etc)
  final SpacingWidgetBuilder spacingWidgetBuilder;

  static Widget _defaultSpacingWidgetBuilder(
    BuildContext context,
    List<SpacingType> spacingTypes,
  ) {
    if (!spacingTypes.contains(SpacingType.defaultSpacing)) {
      return const SizedBox(height: 8);
    }
    return const SizedBox(height: 2);
  }

  @override
  _StreamMessageListViewState createState() => _StreamMessageListViewState();
}

class _StreamMessageListViewState extends State<StreamMessageListView> {
  ItemScrollController? _scrollController;
  void Function(Message)? _onThreadTap;
  final ValueNotifier<bool> _showScrollToBottom = ValueNotifier(false);
  late final ItemPositionsListener _itemPositionListener;
  int? _messageListLength;
  StreamChannelState? streamChannel;
  late StreamChatThemeData _streamTheme;
  late List<String> _userPermissions;
  late int unreadCount;

  int get _initialIndex {
    final initialScrollIndex = widget.initialScrollIndex;
    if (initialScrollIndex != null) return initialScrollIndex;
    if (streamChannel!.initialMessageId != null) {
      final messages = streamChannel!.channel.state!.messages
          .where(widget.messageFilter ??
              defaultMessageFilter(
                streamChannel!.channel.client.state.currentUser!.id,
              ))
          .toList(growable: false);
      final totalMessages = messages.length;
      final messageIndex =
          messages.indexWhere((e) => e.id == streamChannel!.initialMessageId);
      final index = totalMessages - messageIndex;
      if (index != 0) return index + 1;
      return index;
    }

    if (unreadCount > 0) {
      return unreadCount + 1;
    }

    return 0;
  }

  double get _initialAlignment {
    final initialAlignment = widget.initialAlignment;
    if (initialAlignment != null) return initialAlignment;
    return streamChannel!.initialMessageId == null ? 0 : 0.1;
  }

  bool _isInitialMessage(String id) => streamChannel!.initialMessageId == id;

  bool get _upToDate => streamChannel!.channel.state!.isUpToDate;

  bool get _isThreadConversation => widget.parentMessage != null;

  bool _bottomPaginationActive = false;

  int initialIndex = 0;
  double initialAlignment = 0;

  List<Message> messages = <Message>[];

  Map<String, int> messagesIndex = {};

  bool initialMessageHighlightComplete = false;

  bool _inBetweenList = false;

  late final _defaultController = MessageListController();

  MessageListController get _messageListController =>
      widget.messageListController ?? _defaultController;

  @override
  Widget build(BuildContext context) => MessageListCore(
        paginationLimit: widget.paginationLimit,
        messageFilter: widget.messageFilter,
        loadingBuilder: widget.loadingBuilder ??
            (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
        emptyBuilder: widget.emptyBuilder ??
            (context) => Center(
                  child: Text(
                    context.translations.emptyChatMessagesText,
                    style: _streamTheme.textTheme.footnote.copyWith(
                      color: _streamTheme.colorTheme.textHighEmphasis
                          .withOpacity(0.5),
                    ),
                  ),
                ),
        messageListBuilder: widget.messageListBuilder ??
            (context, list) => _buildListView(list),
        messageListController: _messageListController,
        parentMessage: widget.parentMessage,
        errorBuilder: widget.errorBuilder ??
            (BuildContext context, Object error) => Center(
                  child: Text(
                    context.translations.genericErrorText,
                    style: _streamTheme.textTheme.footnote.copyWith(
                      color: _streamTheme.colorTheme.textHighEmphasis
                          .withOpacity(0.5),
                    ),
                  ),
                ),
      );

  Widget _buildListView(List<Message> data) {
    messages = data;
    for (var index = 0; index < messages.length; index++) {
      messagesIndex[messages[index].id] = index;
    }
    final newMessagesListLength = messages.length;

    if (_messageListLength != null) {
      if (_bottomPaginationActive || (_inBetweenList && _upToDate)) {
        if (_itemPositionListener.itemPositions.value.isNotEmpty) {
          final first = _itemPositionListener.itemPositions.value.first;
          final diff = newMessagesListLength - _messageListLength!;
          if (diff > 0) {
            if (messages[0].user?.id !=
                streamChannel!.channel.client.state.currentUser?.id) {
              initialIndex = first.index + diff;
              initialAlignment = first.itemLeadingEdge;
            }
          }
        }
      }
    }

    _messageListLength = newMessagesListLength;

    final itemCount = messages.length + // total messages
            2 + // top + bottom loading indicator
            2 + // header + footer
            1 // parent message
        ;

    final child = Stack(
      alignment: Alignment.center,
      children: [
        StreamConnectionStatusBuilder(
          statusBuilder: (context, status) {
            var statusString = '';
            var showStatus = true;
            switch (status) {
              case ConnectionStatus.connected:
                statusString = context.translations.connectedLabel;
                showStatus = false;
                break;
              case ConnectionStatus.connecting:
                statusString = context.translations.reconnectingLabel;
                break;
              case ConnectionStatus.disconnected:
                statusString = context.translations.disconnectedLabel;
                break;
            }

            return StreamInfoTile(
              showMessage: widget.showConnectionStateTile && showStatus,
              tileAnchor: Alignment.topCenter,
              childAnchor: Alignment.topCenter,
              message: statusString,
              child: LazyLoadScrollView(
                onStartOfPage: () async {
                  _inBetweenList = false;
                  if (!_upToDate) {
                    _bottomPaginationActive = true;
                    return _paginateData(
                      streamChannel,
                      QueryDirection.bottom,
                    );
                  }
                },
                onEndOfPage: () async {
                  _inBetweenList = false;
                  _bottomPaginationActive = false;
                  return _paginateData(
                    streamChannel,
                    QueryDirection.top,
                  );
                },
                onInBetweenOfPage: () {
                  _inBetweenList = true;
                },
                child: ScrollablePositionedList.separated(
                  key: (initialIndex != 0 && initialAlignment != 0)
                      ? ValueKey('$initialIndex-$initialAlignment')
                      : null,
                  keyboardDismissBehavior: widget.keyboardDismissBehavior,
                  itemPositionsListener: _itemPositionListener,
                  initialScrollIndex: initialIndex,
                  initialAlignment: initialAlignment,
                  physics: widget.scrollPhysics,
                  itemScrollController: _scrollController,
                  reverse: widget.reverse,
                  itemCount: itemCount,
                  findChildIndexCallback: (Key key) {
                    final indexedKey = key as IndexedKey;
                    final valueKey = indexedKey.key as ValueKey<String>?;
                    if (valueKey != null) {
                      final index = messagesIndex[valueKey.value];
                      if (index != null) {
                        return ((index + 2) * 2) - 1;
                      }
                    }
                    return null;
                  },

                  // Item Count -> 8 (1 parent, 2 header+footer, 2 top+bottom, 3 messages)
                  // eg:     |Type|         rev(|Index(item)|)     rev(|Index(separator)|)    |Index(item)|    |Index(separator)|
                  //     ParentMessage  ->        7                                             (count-1)
                  //        Separator(ThreadSeparator)          ->           6                                      (count-2)
                  //     Header         ->        6                                             (count-2)
                  //        Separator(Header -> 8??T -> 0||52)  ->           5                                      (count-3)
                  //     TopLoader      ->        5                                             (count-3)
                  //        Separator(0)                        ->           4                                      (count-4)
                  //     Message        ->        4                                             (count-4)
                  //        Separator(2||8)                     ->           3                                      (count-5)
                  //     Message        ->        3                                             (count-5)
                  //        Separator(2||8)                     ->           2                                      (count-6)
                  //     Message        ->        2                                             (count-6)
                  //        Separator(0)                        ->           1                                      (count-7)
                  //     BottomLoader   ->        1                                             (count-7)
                  //        Separator(Footer -> 8??30)          ->           0                                      (count-8)
                  //     Footer         ->        0                                             (count-8)

                  separatorBuilder: (context, i) {
                    if (i == itemCount - 2) {
                      if (widget.parentMessage == null) {
                        return const Offstage();
                      }
                      return _buildThreadSeparator();
                    }
                    if (i == itemCount - 3) {
                      if (widget.reverse
                          ? widget.headerBuilder == null
                          : widget.footerBuilder == null) {
                        if (messages.isNotEmpty) {
                          return _buildDateDivider(messages.last);
                        }
                        if (_isThreadConversation) return const Offstage();
                        return const SizedBox(height: 52);
                      }
                      return const SizedBox(height: 8);
                    }
                    if (i == 0) {
                      if (widget.reverse
                          ? widget.footerBuilder == null
                          : widget.headerBuilder == null) {
                        return const SizedBox(height: 30);
                      }
                      return const SizedBox(height: 8);
                    }

                    if (i == 1 || i == itemCount - 4) {
                      return const Offstage();
                    }

                    late final Message message, nextMessage;
                    if (widget.reverse) {
                      message = messages[i - 1];
                      nextMessage = messages[i - 2];
                    } else {
                      message = messages[i - 2];
                      nextMessage = messages[i - 1];
                    }

                    Widget separator;

                    final isThread = message.replyCount! > 0;

                    if (!Jiffy(message.createdAt.toLocal()).isSame(
                      nextMessage.createdAt.toLocal(),
                      Units.DAY,
                    )) {
                      separator = _buildDateDivider(nextMessage);
                    } else {
                      final timeDiff =
                          Jiffy(nextMessage.createdAt.toLocal()).diff(
                        message.createdAt.toLocal(),
                        Units.MINUTE,
                      );

                      final isNextUserSame =
                          message.user!.id == nextMessage.user?.id;
                      final isDeleted = message.isDeleted;
                      final hasTimeDiff = timeDiff >= 1;

                      final spacingRules = [
                        if (hasTimeDiff) SpacingType.timeDiff,
                        if (!isNextUserSame) SpacingType.otherUser,
                        if (isThread) SpacingType.thread,
                        if (isDeleted) SpacingType.deleted,
                      ];

                      if (spacingRules.isEmpty) {
                        spacingRules.add(SpacingType.defaultSpacing);
                      }

                      separator = widget.spacingWidgetBuilder.call(
                        context,
                        spacingRules,
                      );
                    }

                    if (!isThread && unreadCount > 0 && unreadCount == i - 1) {
                      final unreadMessagesSeparator =
                          _buildUnreadMessagesSeparator(unreadCount);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          separator,
                          unreadMessagesSeparator,
                        ],
                      );
                    }

                    return separator;
                  },
                  itemBuilder: (context, i) {
                    if (i == itemCount - 1) {
                      if (widget.parentMessage == null) {
                        return const Offstage();
                      }
                      return buildParentMessage(widget.parentMessage!);
                    }

                    if (i == itemCount - 2) {
                      if (widget.reverse) {
                        return widget.headerBuilder?.call(context) ??
                            const Offstage();
                      } else {
                        return widget.footerBuilder?.call(context) ??
                            const Offstage();
                      }
                    }

                    final indicatorBuilder =
                        widget.paginationLoadingIndicatorBuilder;

                    if (i == itemCount - 3) {
                      return _loadingIndicator(
                        streamChannel!,
                        QueryDirection.top,
                        indicatorBuilder: indicatorBuilder,
                      );
                    }

                    if (i == 1) {
                      return _loadingIndicator(
                        streamChannel!,
                        QueryDirection.bottom,
                        indicatorBuilder: indicatorBuilder,
                      );
                    }

                    if (i == 0) {
                      if (widget.reverse) {
                        return widget.footerBuilder?.call(context) ??
                            const Offstage();
                      } else {
                        return widget.headerBuilder?.call(context) ??
                            const Offstage();
                      }
                    }

                    const bottomMessageIndex = 2; // 1 -> loader // 0 -> footer

                    final message = messages[i - 2];
                    Widget messageWidget;

                    if (i == bottomMessageIndex) {
                      messageWidget = _buildBottomMessage(
                        context,
                        message,
                        messages,
                        streamChannel!,
                        i - 2,
                      );
                    } else {
                      messageWidget = buildMessage(message, messages, i - 2);
                    }
                    return KeyedSubtree(
                      key: ValueKey(message.id),
                      child: messageWidget,
                    );
                  },
                ),
              ),
            );
          },
        ),
        if (widget.showScrollToBottom)
          BetterStreamBuilder<bool>(
            stream: streamChannel!.channel.state!.isUpToDateStream,
            initialData: streamChannel!.channel.state!.isUpToDate,
            builder: (context, snapshot) => ValueListenableBuilder<bool>(
              valueListenable: _showScrollToBottom,
              child: _buildScrollToBottom(),
              builder: (context, value, child) {
                if (!snapshot || value) {
                  return child!;
                }
                return const Offstage();
              },
            ),
          ),
        if (widget.showFloatingDateDivider)
          _buildFloatingDateDivider(itemCount),
      ],
    );

    final backgroundColor =
        StreamMessageListViewTheme.of(context).backgroundColor;
    final backgroundImage =
        StreamMessageListViewTheme.of(context).backgroundImage;

    if (backgroundColor != null || backgroundImage != null) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor,
          image: backgroundImage,
        ),
        child: child,
      );
    }

    return child;
  }

  Widget _buildUnreadMessagesSeparator(int unreadCount) {
    final unreadMessagesSeparator =
        widget.unreadMessagesSeparatorBuilder?.call(context, unreadCount) ??
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: _streamTheme.colorTheme.bgGradient,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    context.translations.unreadMessagesSeparatorText(
                      unreadCount,
                    ),
                    textAlign: TextAlign.center,
                    style: StreamChannelHeaderTheme.of(context).subtitleStyle,
                  ),
                ),
              ),
            );
    return unreadMessagesSeparator;
  }

  Widget _buildDateDivider(Message message) {
    final divider = widget.dateDividerBuilder != null
        ? widget.dateDividerBuilder!(
            message.createdAt.toLocal(),
          )
        : Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: StreamDateDivider(
              dateTime: message.createdAt.toLocal(),
            ),
          );
    return divider;
  }

  Widget _buildThreadSeparator() {
    if (widget.threadSeparatorBuilder != null) {
      return widget.threadSeparatorBuilder!.call(context);
    }

    final replyCount = widget.parentMessage!.replyCount!;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: _streamTheme.colorTheme.bgGradient,
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Text(
          context.translations.threadSeparatorText(replyCount),
          textAlign: TextAlign.center,
          style: StreamChannelHeaderTheme.of(context).subtitleStyle,
        ),
      ),
    );
  }

  Positioned _buildFloatingDateDivider(int itemCount) => Positioned(
        top: 20,
        left: 0,
        right: 0,
        child: BetterStreamBuilder<Iterable<ItemPosition>>(
          initialData: _itemPositionListener.itemPositions.value,
          stream: _valueListenableToStreamAdapter(
            _itemPositionListener.itemPositions,
          ),
          comparator: (a, b) {
            if (a == null || b == null) {
              return false;
            }
            if (widget.reverse) {
              final aTop = _getTopElementIndex(a);
              final bTop = _getTopElementIndex(b);
              return aTop == bTop;
            } else {
              final aBottom = _getBottomElementIndex(a);
              final bBottom = _getBottomElementIndex(b);
              return aBottom == bBottom;
            }
          },
          builder: (context, values) {
            if (values.isEmpty || messages.isEmpty) {
              return const Offstage();
            }

            int? index;
            if (widget.reverse) {
              index = _getTopElementIndex(values);
            } else {
              index = _getBottomElementIndex(values);
            }

            if ((index == null) ||
                (!_isThreadConversation && index == itemCount - 2) ||
                (_isThreadConversation && index == itemCount - 1)) {
              return const Offstage();
            }

            if (index <= 2 || index >= itemCount - 3) {
              if (widget.reverse) {
                index = itemCount - 4;
              } else {
                index = 2;
              }
            }

            final message = messages[index - 2];
            return widget.dateDividerBuilder != null
                ? widget.dateDividerBuilder!(message.createdAt.toLocal())
                : StreamDateDivider(dateTime: message.createdAt.toLocal());
          },
        ),
      );

  Future<void> _paginateData(
    StreamChannelState? channel,
    QueryDirection direction,
  ) =>
      _messageListController.paginateData!(direction: direction);

  int? _getTopElementIndex(Iterable<ItemPosition> values) {
    final inView = values.where((position) => position.itemLeadingEdge < 1);
    if (inView.isEmpty) return null;
    return inView
        .reduce((max, position) =>
            position.itemLeadingEdge > max.itemLeadingEdge ? position : max)
        .index;
  }

  int? _getBottomElementIndex(Iterable<ItemPosition> values) {
    final inView = values.where((position) => position.itemLeadingEdge < 1);
    if (inView.isEmpty) return null;
    return inView
        .reduce((min, position) =>
            position.itemLeadingEdge < min.itemLeadingEdge ? position : min)
        .index;
  }

  Future<void> scrollToBottomDefaultTapAction(int unreadCount) async {
    this.unreadCount = unreadCount;
    if (unreadCount > 0) {
      streamChannel!.channel.markRead();
    }

    final index = unreadCount > 0 ? unreadCount + 1 : 0;

    if (!_upToDate) {
      _bottomPaginationActive = false;
      initialAlignment = 0;
      initialIndex = 0;
      await streamChannel!.reloadChannel();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController!.jumpTo(index: index);
      });
    } else {
      _scrollController!.scrollTo(
        index: index,
        duration: const Duration(seconds: 1),
        curve: Curves.easeInOut,
      );
    }
  }

  Widget _buildScrollToBottom() => StreamBuilder<int>(
        stream: streamChannel!.channel.state!.unreadCountStream,
        builder: (_, snapshot) {
          if (snapshot.hasError) {
            return const Offstage();
          } else if (!snapshot.hasData) {
            return const Offstage();
          }
          final unreadCount = snapshot.data!;
          if (widget.scrollToBottomBuilder != null) {
            return widget.scrollToBottomBuilder!(
              unreadCount,
              scrollToBottomDefaultTapAction,
            );
          }
          final showUnreadCount = unreadCount > 0 &&
              streamChannel!.channel.state!.members.any((e) =>
                  e.userId ==
                  streamChannel!.channel.client.state.currentUser!.id);
          return Positioned(
            bottom: 8,
            right: 8,
            width: 40,
            height: 40,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                FloatingActionButton(
                  backgroundColor: _streamTheme.colorTheme.barsBg,
                  onPressed: () => scrollToBottomDefaultTapAction(unreadCount),
                  child: widget.reverse
                      ? StreamSvgIcon.down(
                          color: _streamTheme.colorTheme.textHighEmphasis,
                        )
                      : StreamSvgIcon.up(
                          color: _streamTheme.colorTheme.textHighEmphasis,
                        ),
                ),
                if (showUnreadCount)
                  Positioned(
                    width: 20,
                    height: 20,
                    left: 10,
                    top: -10,
                    child: CircleAvatar(
                      child: Padding(
                        padding: const EdgeInsets.all(3),
                        child: Text(
                          '$unreadCount',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      );

  Widget _loadingIndicator(
    StreamChannelState streamChannel,
    QueryDirection direction, {
    WidgetBuilder? indicatorBuilder,
  }) =>
      _LoadingIndicator(
        direction: direction,
        streamTheme: _streamTheme,
        streamChannel: streamChannel,
        isThreadConversation: _isThreadConversation,
        indicatorBuilder: indicatorBuilder,
      );

  Widget _buildBottomMessage(
    BuildContext context,
    Message message,
    List<Message> messages,
    StreamChannelState streamChannel,
    int index,
  ) {
    final messageWidget = buildMessage(message, messages, index);
    return messageWidget;
  }

  Widget buildParentMessage(
    Message message,
  ) {
    final isMyMessage =
        message.user!.id == StreamChat.of(context).currentUser!.id;
    final isOnlyEmoji = message.text?.isOnlyEmoji ?? false;
    final currentUser = StreamChat.of(context).currentUser;
    final members = StreamChannel.of(context).channel.state?.members ?? [];
    final currentUserMember =
        members.firstWhereOrNull((e) => e.user!.id == currentUser!.id);

    final defaultMessageWidget = StreamMessageWidget(
      showReplyMessage: false,
      showResendMessage: false,
      showThreadReplyMessage: false,
      showCopyMessage: false,
      showDeleteMessage: false,
      showEditMessage: false,
      message: message,
      reverse: isMyMessage,
      showUsername: !isMyMessage,
      padding: const EdgeInsets.all(8),
      showSendingIndicator: false,
      borderRadiusGeometry: BorderRadius.only(
        topLeft: const Radius.circular(16),
        bottomLeft:
            isMyMessage ? const Radius.circular(16) : const Radius.circular(2),
        topRight: const Radius.circular(16),
        bottomRight:
            isMyMessage ? const Radius.circular(2) : const Radius.circular(16),
      ),
      textPadding: EdgeInsets.symmetric(
        vertical: 8,
        horizontal: isOnlyEmoji ? 0 : 16.0,
      ),
      borderSide: isMyMessage || isOnlyEmoji ? BorderSide.none : null,
      showUserAvatar: isMyMessage ? DisplayWidget.gone : DisplayWidget.show,
      messageTheme: isMyMessage
          ? _streamTheme.ownMessageTheme
          : _streamTheme.otherMessageTheme,
      onReturnAction: (action) {
        switch (action) {
          case ReturnActionType.none:
            break;
          case ReturnActionType.reply:
            FocusScope.of(context).unfocus();
            widget.onMessageSwiped?.call(message);
            break;
        }
      },
      onMessageTap: (message) {
        widget.onMessageTap?.call(message);
        FocusScope.of(context).unfocus();
      },
      showPinButton: currentUserMember != null &&
          _userPermissions.contains(PermissionType.pinMessage),
    );

    if (widget.parentMessageBuilder != null) {
      return widget.parentMessageBuilder!.call(
        context,
        widget.parentMessage,
        defaultMessageWidget,
      );
    }

    return defaultMessageWidget;
  }

  Widget buildMessage(Message message, List<Message> messages, int index) {
    if ((message.type == 'system' || message.type == 'error') &&
        message.text?.isNotEmpty == true) {
      return widget.systemMessageBuilder?.call(context, message) ??
          StreamSystemMessage(
            message: message,
            onMessageTap: (message) {
              widget.onSystemMessageTap?.call(message);
              FocusScope.of(context).unfocus();
            },
          );
    }

    final userId = StreamChat.of(context).currentUser!.id;
    final isMyMessage = message.user?.id == userId;
    final nextMessage = index - 1 >= 0 ? messages[index - 1] : null;
    final isNextUserSame =
        nextMessage != null && message.user!.id == nextMessage.user!.id;

    num timeDiff = 0;
    if (nextMessage != null) {
      timeDiff = Jiffy(nextMessage.createdAt.toLocal()).diff(
        message.createdAt.toLocal(),
        Units.MINUTE,
      );
    }

    final hasFileAttachment =
        message.attachments.any((it) => it.type == 'file');

    final isThreadMessage =
        message.parentId != null && message.showInChannel == true;

    final hasReplies = message.replyCount! > 0;

    final attachmentBorderRadius = hasFileAttachment ? 12.0 : 14.0;

    final showTimeStamp = (!isThreadMessage || _isThreadConversation) &&
        !hasReplies &&
        (timeDiff >= 1 || !isNextUserSame);

    final showUsername = !isMyMessage &&
        (!isThreadMessage || _isThreadConversation) &&
        !hasReplies &&
        (timeDiff >= 1 || !isNextUserSame);

    final showUserAvatar = isMyMessage
        ? DisplayWidget.gone
        : (timeDiff >= 1 || !isNextUserSame)
            ? DisplayWidget.show
            : DisplayWidget.hide;

    final showSendingIndicator =
        isMyMessage && (index == 0 || timeDiff >= 1 || !isNextUserSame);

    final showInChannelIndicator = !_isThreadConversation && isThreadMessage;
    final showThreadReplyIndicator = !_isThreadConversation && hasReplies;
    final isOnlyEmoji = message.text?.isOnlyEmoji ?? false;

    final hasUrlAttachment =
        message.attachments.any((it) => it.ogScrapeUrl != null);

    final borderSide =
        isOnlyEmoji || hasUrlAttachment || (isMyMessage && !hasFileAttachment)
            ? BorderSide.none
            : null;

    final currentUser = StreamChat.of(context).currentUser;
    final members = StreamChannel.of(context).channel.state?.members ?? [];
    final currentUserMember =
        members.firstWhereOrNull((e) => e.user!.id == currentUser!.id);

    Widget messageWidget = StreamMessageWidget(
      message: message,
      reverse: isMyMessage,
      showReactions: !message.isDeleted,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      showInChannelIndicator: showInChannelIndicator,
      showThreadReplyIndicator: showThreadReplyIndicator,
      showUsername: showUsername,
      showTimestamp: showTimeStamp,
      showSendingIndicator: showSendingIndicator,
      showUserAvatar: showUserAvatar,
      onQuotedMessageTap: (quotedMessageId) async {
        if (messages.map((e) => e.id).contains(quotedMessageId)) {
          final index = messages.indexWhere((m) => m.id == quotedMessageId);
          _scrollController?.scrollTo(
            index: index + 2, // +2 to account for loader and footer
            duration: const Duration(seconds: 1),
            curve: Curves.easeInOut,
            alignment: 0.1,
          );
        } else {
          await streamChannel!
              .loadChannelAtMessage(quotedMessageId)
              .then((_) async {
            initialIndex = 21; // 19 + 2 | 19 is the index of the message
            initialAlignment = 0.1;
          });
        }
      },
      showEditMessage: isMyMessage,
      showDeleteMessage: isMyMessage,
      showThreadReplyMessage: !isThreadMessage &&
          streamChannel?.channel.ownCapabilities
                  .contains(PermissionType.sendReply) ==
              true,
      showFlagButton: !isMyMessage,
      borderSide: borderSide,
      onThreadTap: _onThreadTap,
      attachmentBorderRadiusGeometry: BorderRadius.only(
        topLeft: Radius.circular(attachmentBorderRadius),
        bottomLeft: isMyMessage
            ? Radius.circular(attachmentBorderRadius)
            : Radius.circular(
                (timeDiff >= 1 || !isNextUserSame) &&
                        !(hasReplies || isThreadMessage || hasFileAttachment)
                    ? 0
                    : attachmentBorderRadius,
              ),
        topRight: Radius.circular(attachmentBorderRadius),
        bottomRight: isMyMessage
            ? Radius.circular(
                (timeDiff >= 1 || !isNextUserSame) &&
                        !(hasReplies || isThreadMessage || hasFileAttachment)
                    ? 0
                    : attachmentBorderRadius,
              )
            : Radius.circular(attachmentBorderRadius),
      ),
      attachmentPadding: EdgeInsets.all(hasFileAttachment ? 4 : 2),
      borderRadiusGeometry: BorderRadius.only(
        topLeft: const Radius.circular(16),
        bottomLeft: isMyMessage
            ? const Radius.circular(16)
            : Radius.circular(
                (timeDiff >= 1 || !isNextUserSame) &&
                        !(hasReplies || isThreadMessage)
                    ? 0
                    : 16,
              ),
        topRight: const Radius.circular(16),
        bottomRight: isMyMessage
            ? Radius.circular(
                (timeDiff >= 1 || !isNextUserSame) &&
                        !(hasReplies || isThreadMessage)
                    ? 0
                    : 16,
              )
            : const Radius.circular(16),
      ),
      textPadding: EdgeInsets.symmetric(
        vertical: 8,
        horizontal: isOnlyEmoji ? 0 : 16.0,
      ),
      messageTheme: isMyMessage
          ? _streamTheme.ownMessageTheme
          : _streamTheme.otherMessageTheme,
      onReturnAction: (action) {
        switch (action) {
          case ReturnActionType.none:
            break;
          case ReturnActionType.reply:
            FocusScope.of(context).unfocus();
            widget.onMessageSwiped?.call(message);
            break;
        }
      },
      onMessageTap: (message) {
        widget.onMessageTap?.call(message);
        FocusScope.of(context).unfocus();
      },
      showPinButton: currentUserMember != null &&
          _userPermissions.contains(PermissionType.pinMessage),
    );

    if (widget.messageBuilder != null) {
      messageWidget = widget.messageBuilder!(
        context,
        MessageDetails(
          userId,
          message,
          messages,
          index,
        ),
        messages,
        messageWidget as StreamMessageWidget,
      );
    }

    var child = messageWidget;
    if (!message.isDeleted &&
        !message.isSystem &&
        !message.isEphemeral &&
        widget.onMessageSwiped != null) {
      child = Container(
        decoration: const BoxDecoration(),
        clipBehavior: Clip.hardEdge,
        child: Swipeable(
          onSwipeEnd: () {
            FocusScope.of(context).unfocus();
            widget.onMessageSwiped?.call(message);
          },
          backgroundIcon: StreamSvgIcon.reply(
            color: _streamTheme.colorTheme.accentPrimary,
          ),
          child: child,
        ),
      );
    }

    if (!initialMessageHighlightComplete &&
        widget.highlightInitialMessage &&
        _isInitialMessage(message.id)) {
      final colorTheme = _streamTheme.colorTheme;
      final highlightColor =
          widget.messageHighlightColor ?? colorTheme.highlight;
      child = TweenAnimationBuilder<Color?>(
        tween: ColorTween(
          begin: highlightColor,
          end: colorTheme.barsBg.withOpacity(0),
        ),
        duration: const Duration(seconds: 3),
        onEnd: () => initialMessageHighlightComplete = true,
        builder: (_, color, child) => ColoredBox(
          color: color!,
          child: child,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: child,
        ),
      );
    }
    return child;
  }

  StreamSubscription? _messageNewListener;

  @override
  void initState() {
    _scrollController = widget.scrollController ?? ItemScrollController();
    _itemPositionListener =
        widget.itemPositionListener ?? ItemPositionsListener.create();
    _itemPositionListener.itemPositions
        .addListener(_handleItemPositionsChanged);

    _getOnThreadTap();
    super.initState();
  }

  @override
  void didChangeDependencies() {
    final newStreamChannel = StreamChannel.of(context);
    _streamTheme = StreamChatTheme.of(context);
    _userPermissions = newStreamChannel.channel.ownCapabilities;

    if (newStreamChannel != streamChannel) {
      streamChannel = newStreamChannel;
      _messageNewListener?.cancel();

      unreadCount = streamChannel?.channel.state?.unreadCount ?? 0;
      initialIndex = _initialIndex;
      initialAlignment = _initialAlignment;

      if (_scrollController?.isAttached == true) {
        _scrollController?.jumpTo(
          index: initialIndex,
          alignment: initialAlignment,
        );
      }

      _messageNewListener =
          streamChannel!.channel.on(EventType.messageNew).skip(1)
              //skipping the first event because
              //the StreamController is a BehaviorSubject
              .listen((event) {
        if (_upToDate) {
          _bottomPaginationActive = false;
        }
        if (event.message?.parentId == widget.parentMessage?.id &&
            event.message!.user!.id ==
                streamChannel!.channel.client.state.currentUser!.id) {
          setState(() {
            unreadCount = 0;
          });

          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollController?.scrollTo(
              index: 0,
              duration: const Duration(seconds: 1),
            );
          });
        } else if (streamChannel?.channel.state?.unreadCount != 0) {
          setState(() {
            unreadCount = unreadCount + 1;
          });
        }
      });

      if (_isThreadConversation) {
        streamChannel!.getReplies(widget.parentMessage!.id);
      }

      unreadCount = streamChannel?.channel.state?.unreadCount ?? 0;
    }

    super.didChangeDependencies();
  }

  void _handleItemPositionsChanged() {
    final _itemPositions = _itemPositionListener.itemPositions.value.toList();
    final _firstItemIndex =
        _itemPositions.indexWhere((element) => element.index == 1);
    var _isFirstItemVisible = false;
    if (_firstItemIndex != -1) {
      final _firstItem = _itemPositions[_firstItemIndex];
      _isFirstItemVisible =
          _firstItem.itemLeadingEdge > 0 && _firstItem.itemTrailingEdge < 1;
    }
    if (_isFirstItemVisible) {
      // most recent message is visible
      final channel = streamChannel?.channel;
      if (channel != null) {
        if (_upToDate &&
            channel.config?.readEvents == true &&
            channel.state!.unreadCount > 0) {
          streamChannel!.channel.markRead();
        }
      }
    }
    if (mounted) {
      if (_showScrollToBottom.value == _isFirstItemVisible) {
        _showScrollToBottom.value = !_isFirstItemVisible;
      }
    }
  }

  void _getOnThreadTap() {
    if (widget.onThreadTap != null) {
      _onThreadTap = (Message message) {
        final threadBuilder = widget.threadBuilder;
        widget.onThreadTap!(
          message,
          threadBuilder != null ? threadBuilder(context, message) : null,
        );
      };
    } else if (widget.threadBuilder != null) {
      _onThreadTap = (Message message) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BetterStreamBuilder<Message>(
              stream: streamChannel!.channel.state!.messagesStream.map(
                (messages) => messages.firstWhere((m) => m.id == message.id),
              ),
              initialData: message,
              builder: (_, data) => StreamChannel(
                channel: streamChannel!.channel,
                child: widget.threadBuilder!(context, data),
              ),
            ),
          ),
        );
      };
    }
  }

  @override
  void dispose() {
    if (!_upToDate) {
      streamChannel!.reloadChannel();
    }
    _messageNewListener?.cancel();
    _itemPositionListener.itemPositions
        .removeListener(_handleItemPositionsChanged);
    super.dispose();
  }
}

class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator({
    required this.streamTheme,
    required this.isThreadConversation,
    required this.direction,
    required this.streamChannel,
    this.indicatorBuilder,
  });

  final StreamChatThemeData streamTheme;
  final bool isThreadConversation;
  final QueryDirection direction;
  final StreamChannelState streamChannel;
  final WidgetBuilder? indicatorBuilder;

  @override
  Widget build(BuildContext context) {
    final stream = direction == QueryDirection.top
        ? streamChannel.queryTopMessages
        : streamChannel.queryBottomMessages;
    return BetterStreamBuilder<bool>(
      key: Key('LOADING-INDICATOR $direction'),
      stream: stream,
      initialData: false,
      errorBuilder: (context, error) => ColoredBox(
        color: streamTheme.colorTheme.accentError.withOpacity(0.2),
        child: Center(
          child: Text(context.translations.loadingMessagesError),
        ),
      ),
      builder: (context, data) {
        if (!data) return const Offstage();
        return indicatorBuilder?.call(context) ??
            const Center(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: CircularProgressIndicator(),
              ),
            );
      },
    );
  }
}

Stream<T> _valueListenableToStreamAdapter<T>(ValueListenable<T> listenable) {
  // ignore: close_sinks
  late StreamController<T> _controller;

  void listener() {
    _controller.add(listenable.value);
  }

  void start() {
    listenable.addListener(listener);
  }

  void end() {
    listenable.removeListener(listener);
  }

  _controller = StreamController<T>(
    onListen: start,
    onPause: end,
    onResume: start,
    onCancel: end,
  );

  return _controller.stream;
}
