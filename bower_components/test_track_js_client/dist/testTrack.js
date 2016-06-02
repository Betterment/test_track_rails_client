// Test Track Version 1.0.26
;(function(root, factory) {
    if (typeof define === 'function' && define.amd) {
        // AMD. Register as an anonymous module.
        define(['node-uuid', 'blueimp-md5', 'jquery', 'base-64', 'jquery.cookie'], factory);
    } else {
        // Browser globals (root is window)
        root.TestTrack = factory(root.uuid, root.md5, root.jQuery, root.base64);
    }
})(this, function (uuid, md5, $, base64) {
    'use strict';

    if (typeof uuid === 'undefined') {
        throw new Error('TestTrack depends on node-uuid. Make sure you are including "bower_components/node-uuid/uuid.js"');
    } else if (typeof md5 === 'undefined') {
        throw new Error('TestTrack depends on blueimp-md5. Make sure you are including "bower_components/blueimp-md5/js/md5.js"');
    } else if (typeof $ === 'undefined') {
        throw new Error('TestTrack depends on jquery. You can use your own copy of jquery or the one in "bower_components/jquery/dist/jquery.js"');
    } else  if (typeof $.cookie !== 'function') {
        throw new Error('TestTrack depends on jquery.cookie. You can user your own copy of jquery.cooke or the one in bower_components/jquery.cookie/jquery.cookie.js');
    } else if (typeof base64 === 'undefined') {
        throw new Error('TestTrack depends on base-64. Make sure you are including "bower_components/base-64/base64.js"');
    }

    var ConfigParser = (function() { // jshint ignore:line
        var _ConfigParser = function() {
        };
    
        _ConfigParser.prototype.getConfig = function() {
            if (typeof window.atob === 'function') {
                return JSON.parse(window.atob(window.TT));
            } else {
                return JSON.parse(base64.decode(window.TT));
            }
        };
    
        return _ConfigParser;
    })();
    
    var TestTrackConfig = (function() { // jshint ignore:line
        var config,
            getConfig = function() {
                if (!config) {
                    var parser = new ConfigParser();
                    config = parser.getConfig();
                }
                return config;
            };
    
        return {
            getUrl: function() {
                return getConfig().url;
            },
    
            getCookieDomain: function() {
                return getConfig().cookieDomain;
            },
    
            getSplitRegistry: function() {
                return getConfig().registry;
            },
    
            getAssignmentRegistry: function() {
                return getConfig().assignments;
            }
        };
    })();
    
    var VariantCalculator = (function() { // jshint ignore:line
        var _VariantCalculator = function(options) {
            this.visitor = options.visitor;
            this.splitName = options.splitName;
    
            if (!this.visitor) {
                throw new Error('must provide visitor');
            } else if (!this.splitName) {
                throw new Error('must provide splitName');
            }
        };
    
        _VariantCalculator.prototype.getVariant = function() {
            if (!TestTrackConfig.getSplitRegistry()) {
                return null;
            }
    
            var bucketCeiling = 0,
                assignmentBucket = this.getAssignmentBucket(),
                weighting = this.getWeighting(),
                sortedVariants = this.getSortedVariants();
    
            for (var i = 0; i < sortedVariants.length; i++) {
                var variant = sortedVariants[i];
    
                bucketCeiling += weighting[variant];
                if (bucketCeiling > assignmentBucket) {
                    return variant;
                }
            }
    
            throw new Error('Assignment bucket out of range. ' + assignmentBucket + ' unmatched in ' + this.splitName + ': ' + JSON.stringify(weighting));
        };
    
        _VariantCalculator.prototype.getSplitVisitorHash = function() {
            return md5(this.splitName + this.visitor.getId());
        };
    
        _VariantCalculator.prototype.getHashFixnum = function() {
            return parseInt(this.getSplitVisitorHash().substr(0, 8), 16);
        };
    
        _VariantCalculator.prototype.getAssignmentBucket = function() {
            return this.getHashFixnum() % 100;
        };
    
        _VariantCalculator.prototype.getSortedVariants = function() {
            return this.getVariants().sort();
        };
    
        _VariantCalculator.prototype.getVariants = function() {
            return Object.getOwnPropertyNames(this.getWeighting());
        };
    
        _VariantCalculator.prototype.getWeighting = function() {
            var weighting = TestTrackConfig.getSplitRegistry()[this.splitName];
    
            if (!weighting) {
                var message = 'Unknown split: "' + this.splitName + '"';
                this.visitor.logError(message);
                throw new Error(message);
            }
    
            return weighting;
        };
    
        return _VariantCalculator;
    })();
    
    var AssignmentNotification = (function() { // jshint ignore:line
        var _AssignmentNotification = function(options) {
            this.visitor = options.visitor;
            this.splitName = options.splitName;
            this.variant = options.variant;
    
            if (!this.visitor) {
                throw new Error('must provide visitor');
            } else if (!this.splitName) {
                throw new Error('must provide splitName');
            } else if (!this.variant) {
                throw new Error('must provide variant');
            }
        };
    
        _AssignmentNotification.prototype.send = function() {
            this.persistAssignment();
    
            window.mixpanel.track('SplitAssigned', {
                TTVisitorID: this.visitor.getId(),
                SplitName: this.splitName,
                SplitVariant: this.variant
            }, function(success) {
                this.persistAssignment(success ? 'success' : 'failure');
            }.bind(this));
        };
    
        _AssignmentNotification.prototype.persistAssignment = function(mixpanelResult) {
            return $.ajax(TestTrackConfig.getUrl() + '/api/assignment', {
                method: 'POST',
                dataType: 'json',
                crossDomain: true,
                data: {
                    visitor_id: this.visitor.getId(),
                    split: this.splitName,
                    variant: this.variant,
                    mixpanel_result: mixpanelResult
                }
            }).fail(function(jqXHR, textStatus, errorThrown) {
                var status = jqXHR && jqXHR.status,
                    responseText = jqXHR && jqXHR.responseText;
                this.visitor.logError('test_track persistAssignment error: ' + [jqXHR, status, responseText, textStatus, errorThrown].join(', '));
            }.bind(this));
        };
    
        return _AssignmentNotification;
    })();
    
    var Visitor = (function() { // jshint ignore:line
        var _Visitor = function(options) {
            options = options || {};
            this._id = options.id;
            this._assignmentRegistry = options.assignmentRegistry;
            this._unsyncedSplits = options.unsyncedSplits;
            this._ttOffline = options.ttOffline;
    
            if (!this._id) {
                throw new Error('must provide id');
            } else if (!this._assignmentRegistry) {
                throw new Error('must provide assignmentRegistry');
            } else if (!this._unsyncedSplits) {
                throw new Error('must provide unsyncedSplits');
            }
    
            this._notifyUnsyncedAssignments();
    
            this._errorLogger = function(errorMessage) {
                window.console.error(errorMessage);
            };
        };
    
        _Visitor.loadVisitor = function(visitorId) {
            var deferred = $.Deferred(),
                resolve = function(attrs) {
                    deferred.resolve(new Visitor(attrs));
                };
    
            if (visitorId) {
                if (TestTrackConfig.getAssignmentRegistry()) {
                    resolve({
                        id: visitorId,
                        assignmentRegistry: TestTrackConfig.getAssignmentRegistry(),
                        unsyncedSplits: [],
                        ttOffline: false
                    });
                } else {
                    $.ajax(TestTrackConfig.getUrl() + '/api/visitors/' + visitorId, { method: 'GET', timeout: 5000 })
                        .done(function(attrs) {
                            resolve({
                                id: attrs['id'],
                                assignmentRegistry: attrs['assignment_registry'],
                                unsyncedSplits: attrs['unsynced_splits'],
                                ttOffline: false
                            });
                        })
                        .fail(function() {
                            resolve({
                                id: visitorId,
                                assignmentRegistry: {},
                                unsyncedSplits: [],
                                ttOffline: true
                            });
                        });
                }
            } else {
                resolve({
                    id: uuid.v4(),
                    assignmentRegistry: {},
                    unsyncedSplits: [],
                    ttOffline: false
                });
            }
    
            return deferred.promise();
        };
    
        _Visitor.prototype.getId = function() {
            return this._id;
        };
    
        _Visitor.prototype.getAssignmentRegistry = function() {
            return this._assignmentRegistry;
        };
    
        _Visitor.prototype.getUnsyncedSplits = function() {
            return this._unsyncedSplits;
        };
    
        _Visitor.prototype.vary = function(splitName, configuration, defaultVariant) {
            if (typeof configuration !== 'object') {
                throw new Error('must provide configuration object to `vary` for ' + splitName);
            } else if (!defaultVariant && defaultVariant !== false) {
                throw new Error('must provide defaultVariant to `vary` for ' + splitName);
            }
    
            defaultVariant = defaultVariant.toString();
    
            if (!configuration.hasOwnProperty(defaultVariant)) {
                throw new Error('defaultVariant: ' + defaultVariant + ' must be represented in configuration object');
            }
    
            var variant = this._getAssignmentFor(splitName),
                vary = new VaryDSL({
                    splitName: splitName,
                    assignedVariant: variant,
                    visitor: this
                });
    
    
            for (var variant in configuration) {
                if (configuration.hasOwnProperty(variant)) {
                    if (variant === defaultVariant) {
                        vary.default(variant, configuration[variant]);
                    } else {
                        vary.when(variant, configuration[variant]);
                    }
                }
            }
    
            vary.run();
    
            if (vary.isDefaulted()) {
                this._assignTo(splitName, vary.getDefaultVariant());
            }
    
            if (this._newAssignedVariant) {
                this._notify(splitName, this._newAssignedVariant);
                delete this._newAssignedVariant;
            }
        };
    
        _Visitor.prototype.ab = function(splitName, trueVariant, callback) {
            if (typeof trueVariant === 'function') {
                callback = trueVariant;
                trueVariant = null;
            }
    
            var abConfiguration = new ABConfiguration({
                    splitName: splitName,
                    trueVariant: trueVariant,
                    visitor: this
                }),
                variants = abConfiguration.getVariants(),
                configuration = {};
    
            configuration[variants.true] = function() {
                callback(true);
            };
    
            configuration[variants.false] = function() {
                callback(false);
            };
    
            this.vary(splitName, configuration, variants.false);
        };
    
        _Visitor.prototype.setErrorLogger = function(errorLogger) {
            if (typeof errorLogger !== 'function') {
                throw new Error('must provide function for errorLogger');
            }
    
            this._errorLogger = errorLogger;
        };
    
        _Visitor.prototype.logError = function(errorMessage) {
            this._errorLogger.call(null, errorMessage); // call with null context to ensure we don't leak the visitor object to the outside world
        };
    
        _Visitor.prototype.linkIdentifier = function(identifierType, value) {
            var deferred = $.Deferred(),
                identifier = new Identifier({
                    visitorId: this.getId(),
                    identifierType: identifierType,
                    value: value
                });
    
            identifier.save().then(function(otherVisitor) {
                this._merge(otherVisitor);
                deferred.resolve();
            }.bind(this));
    
            return deferred.promise();
        };
    
        // private
    
        _Visitor.prototype._merge = function(otherVisitor) {
            var assignmentRegistry = this.getAssignmentRegistry(),
                otherAssignmentRegistry = otherVisitor.getAssignmentRegistry();
    
            this._id = otherVisitor.getId();
    
            for (var splitName in otherAssignmentRegistry) {
                if (otherAssignmentRegistry.hasOwnProperty(splitName)) {
                    assignmentRegistry[splitName] = otherAssignmentRegistry[splitName];
                }
            }
        };
    
        _Visitor.prototype._notifyUnsyncedAssignments = function() {
            for (var i = 0; i < this.getUnsyncedSplits().length; i++) {
                var splitName = this.getUnsyncedSplits()[i];
                this._notify(splitName, this.getAssignmentRegistry()[splitName]);
            }
    
            this._unsyncedSplits = [];
        };
    
        _Visitor.prototype._getAssignmentFor = function(splitName) {
            return this.getAssignmentRegistry()[splitName] || this._generateAssignmentFor(splitName);
        };
    
        _Visitor.prototype._generateAssignmentFor = function(splitName) {
            var variant = new VariantCalculator({
                visitor: this,
                splitName: splitName
            }).getVariant();
    
            if (!variant) {
                this._ttOffline = true;
            }
    
            this._assignTo(splitName, variant);
    
            return variant;
        };
    
        _Visitor.prototype._assignTo = function(splitName, variant) {
            if (this._ttOffline) {
                return;
            }
    
            this.getAssignmentRegistry()[splitName] = variant;
            this._newAssignedVariant = variant;
        };
    
        _Visitor.prototype._notify = function(splitName, variant) {
            try {
                var notification = new AssignmentNotification({
                    visitor: this,
                    splitName: splitName,
                    variant: variant
                });
                notification.send();
            } catch(e) {
                this.logError('test_track notify error: ' + e);
            }
        };
    
        return _Visitor;
    })();
    
    var Session = (function() { // jshint ignore:line
        var VISITOR_COOKIE_NAME = 'tt_visitor_id',
            _Session = function() {
                var visitorId = $.cookie(VISITOR_COOKIE_NAME),
                    deferred = $.Deferred();
    
                this._visitorPromise = deferred.promise();
    
                Visitor.loadVisitor(visitorId).then(function(visitor) {
                    deferred.resolve(visitor);
                });
    
                this._setCookie();
            };
    
        _Session.prototype.vary = function(splitName, configuration, defaultVariant) {
            this._visitorPromise.then(function(visitor) {
                visitor.vary(splitName, configuration, defaultVariant);
            });
        };
    
        _Session.prototype.ab = function(splitName, trueVariant, callback) {
            this._visitorPromise.then(function(visitor) {
                visitor.ab(splitName, trueVariant, callback);
            });
        };
    
        _Session.prototype.logIn = function(identifierType, value) {
            var deferred = $.Deferred();
    
            this._visitorPromise.then(function(visitor) {
                visitor.linkIdentifier(identifierType, value).then(function() {
                    this._setCookie();
                    window.mixpanel.identify(visitor.getId());
                    deferred.resolve();
                }.bind(this));
            }.bind(this));
    
            return deferred.promise();
        };
    
        _Session.prototype.signUp = function(identifierType, value) {
            var deferred = $.Deferred();
    
            this._visitorPromise.then(function(visitor) {
                visitor.linkIdentifier(identifierType, value).then(function() {
                    this._setCookie();
                    window.mixpanel.alias(visitor.getId());
                    deferred.resolve();
                }.bind(this));
            }.bind(this));
    
            return deferred.promise();
        };
    
        _Session.prototype.setErrorLogger = function(errorLogger) {
            this._visitorPromise.then(function(visitor) {
                visitor.setErrorLogger(errorLogger);
            });
        };
    
        _Session.prototype._setCookie = function() {
            this._visitorPromise.then(function(visitor) {
                $.cookie(VISITOR_COOKIE_NAME, visitor.getId(), {
                    expires: 365,
                    path: '/',
                    domain: TestTrackConfig.getCookieDomain()
                });
            });
        };
    
        _Session.prototype.getPublicAPI = function() {
            return {
                vary: this.vary.bind(this),
                ab: this.ab.bind(this),
                logIn: this.logIn.bind(this),
                signUp: this.signUp.bind(this),
                setErrorLogger: this.setErrorLogger.bind(this),
                _crx: {
                    loadInfo: function() {
                        var deferred = $.Deferred();
                        this._visitorPromise.then(function(visitor) {
                            deferred.resolve({
                                visitorId: visitor.getId(),
                                splitRegistry: TestTrackConfig.getSplitRegistry(),
                                assignmentRegistry: visitor.getAssignmentRegistry()
                            });
                        });
    
                        return deferred.promise();
                    }.bind(this),
    
                    persistAssignment: function(splitName, variant) {
                        var deferred = $.Deferred();
    
                        this._visitorPromise.then(function(visitor) {
                            var notification = new AssignmentNotification({
                                visitor: visitor,
                                splitName: splitName,
                                variant: variant
                            });
    
                            notification.persistAssignment().then(function() {
                                deferred.resolve();
                            });
                        });
    
                        return deferred.promise();
                    }.bind(this)
                }
            };
        };
    
        return _Session;
    })();
    
    var Identifier = (function() { // jshint ignore:line
        var _Identifier = function(options) {
            this.visitorId = options.visitorId;
            this.identifierType = options.identifierType;
            this.value = options.value;
    
            if (!this.visitorId) {
                throw new Error('must provide visitorId');
            } else if (!this.identifierType) {
                throw new Error('must provide identifierType');
            } else if (!this.value) {
                throw new Error('must provide value');
            }
        };
    
        _Identifier.prototype.save = function(identifierType, value) {
            var deferred = $.Deferred();
    
            $.ajax(TestTrackConfig.getUrl() + '/api/identifier', {
                method: 'POST',
                dataType: 'json',
                crossDomain: true,
                data: {
                    identifier_type: this.identifierType,
                    value: this.value,
                    visitor_id: this.visitorId
                }
            }).then(function(identifierJson) {
                var visitor = new Visitor({
                    id: identifierJson.visitor.id,
                    assignmentRegistry: identifierJson.visitor.assignment_registry,
                    unsyncedSplits: identifierJson.visitor.unsynced_splits
                });
                deferred.resolve(visitor);
            });
    
            return deferred.promise();
        };
    
        return _Identifier;
    })();
    
    var VaryDSL = (function() { // jshint ignore:line
        var _VaryDSL = function(options) {
            if (!options.splitName) {
                throw new Error('must provide splitName');
            } else if (!options.hasOwnProperty('assignedVariant')) {
                throw new Error('must provide assignedVariant');
            } else if (!options.visitor) {
                throw new Error('must provide visitor');
            }
    
            this._splitName = options.splitName;
            this._assignedVariant = options.assignedVariant;
            this._visitor = options.visitor;
            this._splitRegistry = TestTrackConfig.getSplitRegistry();
    
            this._variantHandlers = {};
        };
    
        _VaryDSL.prototype.when = function() {
            // these 5 lines are messy because they ensure that we throw the most appropriate error message if when is called incorrectly.
            // the benefit of this complexity is exercised in the test suite.
            var argArray = Array.prototype.slice.call(arguments, 0),
                lastIndex = argArray.length - 1,
                firstArgIsVariant = typeof argArray[0] !== 'function' && argArray.length > 0,
                variants = firstArgIsVariant ? argArray.slice(0, Math.max(1, lastIndex)): [],
                handler = argArray[lastIndex];
    
            if (variants.length === 0) {
                throw new Error('must provide at least one variant');
            }
    
            for (var i = 0; i < variants.length; i++) {
                this._assignHandlerToVariant(variants[i], handler);
            }
        };
    
        _VaryDSL.prototype.default = function(variant, handler) {
            if (this._defaultVariant) {
                throw new Error('must provide exactly one `default`');
            }
    
            this._defaultVariant = this._assignHandlerToVariant(variant, handler);
        };
    
        _VaryDSL.prototype.run = function() {
            this._validate();
    
            var chosenHandler;
            if (this._variantHandlers[this._assignedVariant]) {
                chosenHandler = this._variantHandlers[this._assignedVariant];
            } else {
                chosenHandler = this._variantHandlers[this.getDefaultVariant()];
                this._defaulted = true;
            }
    
            chosenHandler();
        };
    
        _VaryDSL.prototype.isDefaulted = function() {
            return this._defaulted || false;
        };
    
        _VaryDSL.prototype.getDefaultVariant = function() {
            return this._defaultVariant;
        };
    
        // private
    
        _VaryDSL.prototype._assignHandlerToVariant = function(variant, handler) {
            if (typeof handler !== 'function') {
                throw new Error('must provide handler for ' + variant);
            }
    
            variant = variant.toString();
    
            if (this._getSplit() && !this._getSplit().hasOwnProperty(variant)) {
                this._visitor.logError('configures unknown variant ' + variant);
            }
    
            this._variantHandlers[variant] = handler;
    
            return variant;
        };
    
        _VaryDSL.prototype._validate = function() {
            if (!this.getDefaultVariant()) {
                throw new Error('must provide exactly one `default`');
            } else if (this._getVariants().length < 2) {
                throw new Error('must provide at least one `when`');
            } else if (!this._getSplit()) {
                return;
            }
    
            var missingVariants = this._getMissingVariants();
    
            if (missingVariants.length > 0) {
                var missingVariantSentence = missingVariants.join(', ').replace(/, (.+)$/, ' and $1');
                this._visitor.logError('does not configure variants ' + missingVariantSentence);
            }
        };
    
        _VaryDSL.prototype._getSplit = function() {
            if (this._splitRegistry) {
                return this._splitRegistry[this._splitName];
            } else {
                return null;
            }
        };
    
        _VaryDSL.prototype._getVariants = function() {
            return Object.getOwnPropertyNames(this._variantHandlers);
        };
    
        _VaryDSL.prototype._getMissingVariants = function() {
            var variants = this._getVariants(),
                split = this._getSplit(),
                splitVariants = Object.getOwnPropertyNames(split),
                missingVariants = [];
    
            for (var i = 0; i < splitVariants.length; i++) {
                var splitVariant = splitVariants[i];
    
                if (variants.indexOf(splitVariant) === -1) {
                    missingVariants.push(splitVariant);
                }
            }
    
            return missingVariants;
        };
    
        return _VaryDSL;
    })();
    
    var ABConfiguration = (function() { // jshint ignore:line
        var _ABConfiguration = function(options) {
            if (!options.splitName) {
                throw new Error('must provide splitName');
            } else if (!options.hasOwnProperty('trueVariant')) {
                throw new Error('must provide trueVariant');
            } else if (!options.visitor) {
                throw new Error('must provide visitor');
            }
    
            this._splitName = options.splitName;
            this._trueVariant = options.trueVariant;
            this._visitor = options.visitor;
            this._splitRegistry = TestTrackConfig.getSplitRegistry();
        };
    
        _ABConfiguration.prototype.getVariants = function() {
            var splitVariants = this._getSplitVariants();
            if (splitVariants && splitVariants.length > 2) {
                this._visitor.logError('A/B for ' + this._splitName + ' configures split with more than 2 variants');
            }
    
            return {
                'true': this._getTrueVariant(),
                'false': this._getFalseVariant()
            };
        };
    
        // private
    
        _ABConfiguration.prototype._getTrueVariant = function() {
            return this._trueVariant || true;
        };
    
        _ABConfiguration.prototype._getFalseVariant = function() {
            var nonTrueVariants = this._getNonTrueVariants();
            return nonTrueVariants ? nonTrueVariants.sort()[0] : false;
        };
    
        _ABConfiguration.prototype._getNonTrueVariants = function() {
            var splitVariants = this._getSplitVariants();
    
            if (splitVariants) {
                var trueVariant = this._getTrueVariant(),
                    trueVariantIndex = splitVariants.indexOf(trueVariant);
    
                if (trueVariantIndex !== -1) {
                    splitVariants.splice(trueVariantIndex, 1); // remove the true variant
                }
    
                return splitVariants;
            } else {
                return null;
            }
        };
    
        _ABConfiguration.prototype._getSplit = function() {
            return this._splitRegistry ? this._splitRegistry[this._splitName] : null;
        };
    
        _ABConfiguration.prototype._getSplitVariants = function() {
            return this._getSplit() && Object.getOwnPropertyNames(this._getSplit());
        };
    
        return _ABConfiguration;
    })();
    

    var TestTrack = new Session().getPublicAPI(),
        notifyListener = function() {
            window.dispatchEvent(new CustomEvent('tt:lib:loaded', {
                detail: {
                    TestTrack: TestTrack
                }
            }));
        };

    try {
        // Add class to body of page after body is loaded to enable chrome extension support
        $(document).ready(function() {
            $(document.body).addClass('_tt');
            try {
                window.dispatchEvent(new CustomEvent('tt:class:added'));
            } catch(e) {}
        });
        // **** The order of these two lines is important, they support 2 different cases:
        // in the case where there is already code listening for 'tt:lib:loaded', trigger it immediately
        // in the case where there is not yet code listening for 'tt:lib:loaded', listen for 'tt:listener:ready' and then trigger 'tt:lib:loaded'
        notifyListener();
        window.addEventListener('tt:listener:ready', notifyListener);
    } catch(e) {}

    return TestTrack;
});
